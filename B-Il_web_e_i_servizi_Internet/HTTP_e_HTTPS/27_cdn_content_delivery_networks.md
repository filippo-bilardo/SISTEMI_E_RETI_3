# 26. Content Delivery Networks (CDN)

## 26.1 Introduzione

**CDN (Content Delivery Network)** è una rete geograficamente distribuita di server che memorizza copie in cache dei contenuti web per servirli velocemente agli utenti.

**Come funziona:**

```
Senza CDN:
User (Tokyo) → Origin Server (New York)
Latency: 200ms, Distance: 11,000 km

Con CDN:
User (Tokyo) → CDN Edge (Tokyo)
Latency: 5ms, Distance: 50 km
```

**Vantaggi:**
- ⚡ **Faster load times:** Serve da server geograficamente vicini
- 📉 **Reduced bandwidth:** Offload traffic dall'origin server
- 🛡️ **DDoS protection:** Assorbe attacchi distribuiti
- 🌍 **Global availability:** Ridondanza geografica
- 📈 **Scalability:** Gestisce picchi di traffico
- 💰 **Cost savings:** Meno bandwidth sull'origin

**Major CDN providers:**
- **Cloudflare:** Free tier, 200+ locations
- **AWS CloudFront:** Integrazione AWS
- **Akamai:** Enterprise, 4000+ locations
- **Fastly:** Real-time purge, programmable edge
- **Google Cloud CDN:** Integrazione GCP
- **Azure CDN:** Integrazione Azure

---

## 26.2 CDN Architecture

### 26.2.1 - Edge Locations

**Distributed network:**

```
                    Origin Server
                    (New York)
                         |
         +---------------+---------------+
         |               |               |
    Edge Server     Edge Server     Edge Server
     (London)        (Tokyo)       (São Paulo)
         |               |               |
   Users Europe    Users Asia    Users South America
```

**Edge caching:**

```
1. User request → Nearest edge server
2. Edge checks cache:
   - Hit → Serve from cache (FAST)
   - Miss → Fetch from origin, cache, serve
3. Subsequent requests → Served from cache
```

### 26.2.2 - Cache Tiers

**Multi-tier CDN:**

```
User → Edge POP (Point of Presence)
         ↓ (cache miss)
      Regional POP
         ↓ (cache miss)
      Origin Shield
         ↓ (cache miss)
      Origin Server
```

**Benefits:**
- Edge POP: Lowest latency
- Regional POP: Reduces origin load
- Origin Shield: Protects origin from stampede

---

## 26.3 CDN Configuration

### 26.3.1 - Cloudflare Setup

**1. DNS Setup:**

```
1. Add site to Cloudflare
2. Update nameservers:
   - ns1.cloudflare.com
   - ns2.cloudflare.com

3. DNS records (proxied through CDN):
   Type  Name              Value            Proxy
   A     example.com       1.2.3.4          ✅ Proxied (CDN)
   A     www.example.com   1.2.3.4          ✅ Proxied
   A     api.example.com   1.2.3.4          ❌ DNS only (no CDN)
```

**2. Cache configuration:**

```nginx
# Origin server (Nginx)
server {
    listen 80;
    server_name example.com;
    
    # Static assets (cache 1 year)
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, max-age=31536000, immutable";
    }
    
    # HTML (no cache, revalidate)
    location ~* \.html$ {
        add_header Cache-Control "public, max-age=0, must-revalidate";
    }
    
    # API (no cache)
    location /api/ {
        add_header Cache-Control "private, no-cache, no-store, must-revalidate";
        proxy_pass http://backend;
    }
}
```

**3. Cloudflare Page Rules:**

```
Page Rule 1: example.com/static/*
- Cache Level: Cache Everything
- Edge Cache TTL: 1 month

Page Rule 2: example.com/api/*
- Cache Level: Bypass

Page Rule 3: example.com/*
- Cache Level: Standard
- Browser Cache TTL: 4 hours
```

### 26.3.2 - AWS CloudFront

**CloudFormation template:**

```yaml
Resources:
  CloudFrontDistribution:
    Type: AWS::CloudFront::Distribution
    Properties:
      DistributionConfig:
        Enabled: true
        Comment: My CDN Distribution
        
        # Origin (S3 or custom)
        Origins:
          - Id: S3Origin
            DomainName: my-bucket.s3.amazonaws.com
            S3OriginConfig:
              OriginAccessIdentity: !Sub 'origin-access-identity/cloudfront/${CloudFrontOAI}'
          
          - Id: CustomOrigin
            DomainName: api.example.com
            CustomOriginConfig:
              HTTPPort: 80
              HTTPSPort: 443
              OriginProtocolPolicy: https-only
              OriginSSLProtocols:
                - TLSv1.2
        
        # Default cache behavior
        DefaultCacheBehavior:
          TargetOriginId: S3Origin
          ViewerProtocolPolicy: redirect-to-https
          AllowedMethods:
            - GET
            - HEAD
            - OPTIONS
          CachedMethods:
            - GET
            - HEAD
          Compress: true
          ForwardedValues:
            QueryString: false
            Cookies:
              Forward: none
          MinTTL: 0
          DefaultTTL: 86400
          MaxTTL: 31536000
        
        # Path patterns
        CacheBehaviors:
          # API (no cache)
          - PathPattern: /api/*
            TargetOriginId: CustomOrigin
            ViewerProtocolPolicy: https-only
            AllowedMethods:
              - DELETE
              - GET
              - HEAD
              - OPTIONS
              - PATCH
              - POST
              - PUT
            ForwardedValues:
              QueryString: true
              Headers:
                - Authorization
                - Content-Type
              Cookies:
                Forward: all
            MinTTL: 0
            DefaultTTL: 0
            MaxTTL: 0
          
          # Static assets (long cache)
          - PathPattern: /static/*
            TargetOriginId: S3Origin
            ViewerProtocolPolicy: https-only
            Compress: true
            ForwardedValues:
              QueryString: false
            MinTTL: 31536000
            DefaultTTL: 31536000
            MaxTTL: 31536000
        
        # Custom SSL certificate
        ViewerCertificate:
          AcmCertificateArn: !Ref SSLCertificate
          SslSupportMethod: sni-only
          MinimumProtocolVersion: TLSv1.2_2021
        
        # Aliases
        Aliases:
          - example.com
          - www.example.com
        
        # Price class (all edge locations vs limited)
        PriceClass: PriceClass_All

  CloudFrontOAI:
    Type: AWS::CloudFront::CloudFrontOriginAccessIdentity
    Properties:
      CloudFrontOriginAccessIdentityConfig:
        Comment: OAI for S3 access
```

**Terraform configuration:**

```hcl
resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "My CDN"
  default_root_object = "index.html"

  origin {
    domain_name = aws_s3_bucket.static.bucket_regional_domain_name
    origin_id   = "S3-static"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-static"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  aliases = ["example.com", "www.example.com"]
}
```

### 26.3.3 - Cache Control Headers

**Origin server headers:**

```javascript
const express = require('express');
const app = express();

// Static assets (immutable, 1 year)
app.use('/static', express.static('public', {
    maxAge: '1y',
    immutable: true,
    setHeaders: (res, path) => {
        res.set('Cache-Control', 'public, max-age=31536000, immutable');
        res.set('CDN-Cache-Control', 'max-age=31536000');
    }
}));

// HTML (revalidate)
app.get('*.html', (req, res) => {
    res.set('Cache-Control', 'public, max-age=0, must-revalidate');
    res.set('CDN-Cache-Control', 'max-age=3600'); // CDN cache 1 hour
    res.sendFile('index.html');
});

// API (no cache)
app.get('/api/*', (req, res) => {
    res.set('Cache-Control', 'private, no-cache, no-store, must-revalidate');
    res.set('CDN-Cache-Control', 'no-store'); // CDN don't cache
    res.json({ data: 'dynamic' });
});

// User-specific content (private cache)
app.get('/dashboard', authenticate, (req, res) => {
    res.set('Cache-Control', 'private, max-age=300'); // Browser cache 5 min
    res.set('CDN-Cache-Control', 'no-store'); // CDN don't cache
    res.json({ user_data: req.user });
});

app.listen(3000);
```

---

## 26.4 Cache Invalidation

### 26.4.1 - Purge Cache

**Cloudflare API:**

```bash
# Purge everything
curl -X POST "https://api.cloudflare.com/client/v4/zones/{zone_id}/purge_cache" \
  -H "Authorization: Bearer {api_token}" \
  -H "Content-Type: application/json" \
  --data '{"purge_everything":true}'

# Purge specific URLs
curl -X POST "https://api.cloudflare.com/client/v4/zones/{zone_id}/purge_cache" \
  -H "Authorization: Bearer {api_token}" \
  -H "Content-Type: application/json" \
  --data '{
    "files": [
      "https://example.com/styles.css",
      "https://example.com/bundle.js"
    ]
  }'

# Purge by tag
curl -X POST "https://api.cloudflare.com/client/v4/zones/{zone_id}/purge_cache" \
  -H "Authorization: Bearer {api_token}" \
  -H "Content-Type: application/json" \
  --data '{"tags":["static-assets"]}'
```

**AWS CloudFront invalidation:**

```bash
# Invalidate specific paths
aws cloudfront create-invalidation \
  --distribution-id E123456789 \
  --paths "/index.html" "/styles.css" "/bundle.js"

# Invalidate all
aws cloudfront create-invalidation \
  --distribution-id E123456789 \
  --paths "/*"
```

**Node.js automated invalidation:**

```javascript
const AWS = require('aws-sdk');
const cloudfront = new AWS.CloudFront();

const invalidateCache = async (paths) => {
    const params = {
        DistributionId: 'E123456789',
        InvalidationBatch: {
            CallerReference: Date.now().toString(),
            Paths: {
                Quantity: paths.length,
                Items: paths
            }
        }
    };
    
    const result = await cloudfront.createInvalidation(params).promise();
    console.log('Invalidation created:', result.Invalidation.Id);
    
    return result;
};

// After deployment
invalidateCache(['/index.html', '/bundle-*.js', '/styles-*.css']);
```

### 26.4.2 - Cache Versioning

**URL versioning (preferred):**

```html
<!-- Old version -->
<link rel="stylesheet" href="/styles.css?v=1.0.0">
<script src="/bundle.js?v=1.0.0"></script>

<!-- New version (different URL = automatic cache bust) -->
<link rel="stylesheet" href="/styles.css?v=1.1.0">
<script src="/bundle.js?v=1.1.0"></script>
```

**Webpack hash-based naming:**

```javascript
// webpack.config.js
module.exports = {
    output: {
        filename: '[name].[contenthash].js',
        path: path.resolve(__dirname, 'dist')
    }
};

// Output:
// bundle.a1b2c3d4.js
// styles.e5f6g7h8.css

// When content changes → different hash → different filename → no cache issue!
```

---

## 26.5 CDN Performance Optimization

### 26.5.1 - HTTP/2 & HTTP/3

**Enable modern protocols:**

```
Cloudflare: HTTP/2, HTTP/3 enabled by default
AWS CloudFront: HTTP/2 by default, HTTP/3 opt-in
Fastly: HTTP/2, HTTP/3 (QUIC) supported
```

**Benefits:**
- Multiplexing: Multiple requests in single connection
- Header compression: HPACK reduces overhead
- Server push: Proactively send resources
- HTTP/3 (QUIC): 0-RTT, better mobile performance

### 26.5.2 - Image Optimization

**Cloudflare Image Resizing:**

```html
<!-- Original image -->
<img src="https://example.com/photo.jpg">

<!-- Cloudflare resized (on-the-fly) -->
<img src="https://example.com/cdn-cgi/image/width=800,quality=80/photo.jpg">

<!-- Responsive images -->
<img srcset="
  https://example.com/cdn-cgi/image/width=400/photo.jpg 400w,
  https://example.com/cdn-cgi/image/width=800/photo.jpg 800w,
  https://example.com/cdn-cgi/image/width=1200/photo.jpg 1200w
" sizes="(max-width: 600px) 400px, (max-width: 1200px) 800px, 1200px">

<!-- WebP conversion -->
<img src="https://example.com/cdn-cgi/image/format=webp/photo.jpg">
```

**AWS CloudFront + Lambda@Edge:**

```javascript
// Lambda@Edge (resize images on-the-fly)
exports.handler = async (event) => {
    const request = event.Records[0].cf.request;
    const uri = request.uri;
    
    // Parse resize parameters from URL
    const match = uri.match(/\/(\d+)x(\d+)\/(.*)/);
    if (match) {
        const [, width, height, filename] = match;
        
        // Fetch original from S3
        const s3 = new AWS.S3();
        const original = await s3.getObject({
            Bucket: 'my-images',
            Key: filename
        }).promise();
        
        // Resize with Sharp
        const sharp = require('sharp');
        const resized = await sharp(original.Body)
            .resize(parseInt(width), parseInt(height))
            .toBuffer();
        
        return {
            status: '200',
            headers: {
                'content-type': [{ value: 'image/jpeg' }],
                'cache-control': [{ value: 'max-age=31536000' }]
            },
            body: resized.toString('base64'),
            bodyEncoding: 'base64'
        };
    }
    
    return request;
};
```

### 26.5.3 - Prefetching & Preconnecting

**DNS prefetch & preconnect:**

```html
<!DOCTYPE html>
<html>
<head>
    <!-- DNS prefetch (resolve DNS early) -->
    <link rel="dns-prefetch" href="//cdn.example.com">
    <link rel="dns-prefetch" href="//api.example.com">
    
    <!-- Preconnect (DNS + TCP + TLS handshake) -->
    <link rel="preconnect" href="https://cdn.example.com">
    
    <!-- Prefetch resources (low priority) -->
    <link rel="prefetch" href="https://cdn.example.com/next-page.js">
    
    <!-- Preload critical resources (high priority) -->
    <link rel="preload" href="https://cdn.example.com/critical.css" as="style">
    <link rel="preload" href="https://cdn.example.com/font.woff2" as="font" crossorigin>
</head>
<body>
    <!-- Content -->
</body>
</html>
```

---

## 26.6 CDN Security

### 26.6.1 - Origin Protection

**Restrict access to CDN only:**

```nginx
# Nginx: Only allow Cloudflare IPs
geo $cloudflare_ip {
    default 0;
    103.21.244.0/22 1;
    103.22.200.0/22 1;
    103.31.4.0/22 1;
    # ... (full list from cloudflare.com/ips)
}

server {
    listen 80;
    server_name example.com;
    
    # Block direct access
    if ($cloudflare_ip = 0) {
        return 403 "Direct access not allowed";
    }
    
    # Verify Cloudflare header
    if ($http_cf_connecting_ip = "") {
        return 403 "Missing CF header";
    }
    
    # Get real client IP
    set_real_ip_from 103.21.244.0/22;
    # ... (all Cloudflare IPs)
    real_ip_header CF-Connecting-IP;
    
    location / {
        root /var/www/html;
    }
}
```

**AWS CloudFront with custom header:**

```nginx
# Origin server
server {
    listen 80;
    server_name origin.example.com;
    
    # Require secret header
    if ($http_x_origin_verify != "secret-token-12345") {
        return 403 "Access denied";
    }
    
    location / {
        root /var/www/html;
    }
}
```

```yaml
# CloudFront
Origins:
  - Id: CustomOrigin
    DomainName: origin.example.com
    CustomOriginConfig:
      OriginProtocolPolicy: https-only
    OriginCustomHeaders:
      - HeaderName: X-Origin-Verify
        HeaderValue: secret-token-12345
```

### 26.6.2 - Signed URLs & Cookies

**AWS CloudFront signed URLs:**

```javascript
const AWS = require('aws-sdk');
const cloudfront = new AWS.CloudFront.Signer(
    'KEYPAIRID',
    fs.readFileSync('./private-key.pem', 'utf8')
);

const signUrl = (url, expiresIn = 3600) => {
    const expires = Math.floor(Date.now() / 1000) + expiresIn;
    
    const signedUrl = cloudfront.getSignedUrl({
        url: url,
        expires: expires
    });
    
    return signedUrl;
};

// Usage
app.get('/download/:file', authenticate, (req, res) => {
    const file = req.params.file;
    const cdnUrl = `https://d123.cloudfront.net/private/${file}`;
    
    // Generate signed URL (valid 1 hour)
    const signedUrl = signUrl(cdnUrl, 3600);
    
    res.json({ download_url: signedUrl });
});

// Client receives:
// https://d123.cloudfront.net/private/file.pdf?
//   Expires=1698765432&
//   Signature=ABC123...&
//   Key-Pair-Id=KEYPAIRID
```

**Cloudflare signed URLs:**

```javascript
const crypto = require('crypto');

const signCloudflareUrl = (url, secret, expiresIn = 3600) => {
    const expires = Math.floor(Date.now() / 1000) + expiresIn;
    const token = crypto
        .createHmac('sha256', secret)
        .update(`${url}${expires}`)
        .digest('hex');
    
    return `${url}?token=${token}&expires=${expires}`;
};

// Usage
const signedUrl = signCloudflareUrl(
    'https://example.com/private/video.mp4',
    'my-secret-key',
    3600
);
```

---

## 26.7 Advanced CDN Features

### 26.7.1 - Edge Computing (Workers)

**Cloudflare Workers:**

```javascript
// Worker script (runs at edge)
addEventListener('fetch', event => {
    event.respondWith(handleRequest(event.request));
});

async function handleRequest(request) {
    const url = new URL(request.url);
    
    // A/B testing at edge
    const variant = Math.random() < 0.5 ? 'A' : 'B';
    
    // Modify HTML at edge
    if (url.pathname === '/') {
        const response = await fetch(request);
        const html = await response.text();
        
        const modified = html.replace(
            '<title>',
            `<title>[Variant ${variant}] `
        );
        
        return new Response(modified, {
            headers: {
                'Content-Type': 'text/html',
                'X-Variant': variant
            }
        });
    }
    
    // Geo-redirect
    const country = request.headers.get('CF-IPCountry');
    if (country === 'CN' && !url.pathname.startsWith('/cn/')) {
        return Response.redirect('/cn' + url.pathname, 302);
    }
    
    // API proxy with authentication
    if (url.pathname.startsWith('/api/')) {
        const apiKey = request.headers.get('X-API-Key');
        
        if (!apiKey || apiKey !== 'valid-key') {
            return new Response('Unauthorized', { status: 401 });
        }
        
        return fetch(`https://backend.example.com${url.pathname}`, {
            headers: {
                'Authorization': `Bearer ${apiKey}`
            }
        });
    }
    
    return fetch(request);
}
```

**AWS Lambda@Edge:**

```javascript
// Viewer request (before cache lookup)
exports.handler = async (event) => {
    const request = event.Records[0].cf.request;
    const headers = request.headers;
    
    // Mobile detection
    const userAgent = headers['user-agent'][0].value;
    if (/mobile/i.test(userAgent)) {
        request.uri = request.uri.replace(/^\//, '/mobile/');
    }
    
    // Authentication
    const auth = headers['authorization'];
    if (!auth) {
        return {
            status: '401',
            statusDescription: 'Unauthorized',
            headers: {
                'www-authenticate': [{ value: 'Basic' }]
            }
        };
    }
    
    return request;
};

// Origin response (modify response before caching)
exports.handler = async (event) => {
    const response = event.Records[0].cf.response;
    
    // Add security headers
    response.headers['strict-transport-security'] = [{
        value: 'max-age=31536000; includeSubDomains'
    }];
    
    return response;
};
```

### 26.7.2 - Streaming & Live Video

**HLS (HTTP Live Streaming) via CDN:**

```
Video pipeline:
1. Encoder → Segments video into .ts chunks
2. Generates .m3u8 playlist
3. Upload to CDN
4. CDN serves chunks globally

CDN URL:
https://cdn.example.com/live/stream.m3u8
```

**Cloudflare Stream:**

```javascript
// Upload video to Cloudflare Stream
const uploadVideo = async (videoPath) => {
    const formData = new FormData();
    formData.append('file', fs.createReadStream(videoPath));
    
    const response = await fetch(
        'https://api.cloudflare.com/client/v4/accounts/{account_id}/stream',
        {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${API_TOKEN}`
            },
            body: formData
        }
    );
    
    const data = await response.json();
    
    // CDN URLs automatically generated:
    // HLS: https://customer-xxx.cloudflarestream.com/{video_id}/manifest/video.m3u8
    // DASH: https://customer-xxx.cloudflarestream.com/{video_id}/manifest/video.mpd
    
    return data.result;
};

// Embed video
const embedUrl = `https://customer-xxx.cloudflarestream.com/${videoId}/iframe`;
```

---

## 26.8 Monitoring & Analytics

### 26.8.1 - CDN Metrics

**Cloudflare Analytics API:**

```javascript
const fetch = require('node-fetch');

const getCDNMetrics = async (zoneId, since, until) => {
    const query = `
        query {
            viewer {
                zones(filter: { zoneTag: "${zoneId}" }) {
                    httpRequests1dGroups(
                        filter: {
                            date_geq: "${since}",
                            date_lt: "${until}"
                        }
                    ) {
                        sum {
                            requests
                            bytes
                            cachedRequests
                            cachedBytes
                        }
                        dimensions {
                            date
                        }
                    }
                }
            }
        }
    `;
    
    const response = await fetch('https://api.cloudflare.com/client/v4/graphql', {
        method: 'POST',
        headers: {
            'Authorization': `Bearer ${API_TOKEN}`,
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ query })
    });
    
    const data = await response.json();
    const metrics = data.data.viewer.zones[0].httpRequests1dGroups[0].sum;
    
    const cacheHitRate = (metrics.cachedRequests / metrics.requests * 100).toFixed(1);
    const bandwidthSaved = ((1 - metrics.cachedBytes / metrics.bytes) * 100).toFixed(1);
    
    console.log(`Requests: ${metrics.requests}`);
    console.log(`Cache hit rate: ${cacheHitRate}%`);
    console.log(`Bandwidth saved: ${bandwidthSaved}%`);
    
    return metrics;
};
```

**AWS CloudFront metrics (CloudWatch):**

```javascript
const AWS = require('aws-sdk');
const cloudwatch = new AWS.CloudWatch();

const getCloudfrontMetrics = async (distributionId) => {
    const params = {
        Namespace: 'AWS/CloudFront',
        MetricName: 'Requests',
        Dimensions: [{
            Name: 'DistributionId',
            Value: distributionId
        }],
        StartTime: new Date(Date.now() - 24 * 60 * 60 * 1000),
        EndTime: new Date(),
        Period: 3600,
        Statistics: ['Sum']
    };
    
    const data = await cloudwatch.getMetricStatistics(params).promise();
    
    return data.Datapoints;
};
```

---

## 26.9 Best Practices

### 26.9.1 - Complete Production Setup

**Multi-CDN strategy:**

```javascript
// Failover between CDNs
const CDN_URLS = [
    'https://cdn1.cloudflare.com',
    'https://cdn2.cloudfront.net',
    'https://origin.example.com'
];

const fetchWithFailover = async (path) => {
    for (const cdn of CDN_URLS) {
        try {
            const response = await fetch(`${cdn}${path}`, {
                timeout: 5000
            });
            
            if (response.ok) {
                return response;
            }
        } catch (error) {
            console.error(`CDN ${cdn} failed:`, error);
            continue; // Try next CDN
        }
    }
    
    throw new Error('All CDNs failed');
};
```

**Optimal cache strategy:**

```nginx
# Origin server
server {
    listen 80;
    server_name origin.example.com;
    
    # Static assets (immutable, max cache)
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, max-age=31536000, immutable";
        add_header CDN-Cache-Control "max-age=31536000";
        add_header Vary "Accept-Encoding";
    }
    
    # HTML (short browser cache, longer CDN cache)
    location ~* \.html$ {
        add_header Cache-Control "public, max-age=300, must-revalidate";
        add_header CDN-Cache-Control "max-age=3600, stale-while-revalidate=86400";
        add_header Vary "Accept-Encoding";
    }
    
    # API (no cache)
    location /api/ {
        add_header Cache-Control "private, no-cache, no-store, must-revalidate";
        add_header CDN-Cache-Control "no-store";
        proxy_pass http://backend;
    }
}
```

---

**Capitolo 26 completato!**

Prossimo: **Capitolo 27 - WebSockets e Real-Time Communication**
