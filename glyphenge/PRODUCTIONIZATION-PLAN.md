# Glyphenge Productionization Plan

## Current Status Assessment (January 2025)

**What Works:**
- ✅ Server-side SVG rendering with 3 adaptive templates
- ✅ POST /create endpoint for tapestry creation
- ✅ BDO integration with emojicode generation
- ✅ Dual URL access (emojicode + alphanumeric)
- ✅ Docker container deployment (November 2025 test)
- ✅ Linktree import integration
- ✅ Sharon test suite (10 comprehensive tests)
- ✅ Client-side URL construction architecture
- ✅ Environment variable configuration support

**Current Deployment:**
- Local development: `http://localhost:3010`
- Docker standalone container tested November 7, 2025
- Test environment: Port 5125 (Docker Base 1)
- BDO service: localhost:3003 (default)

## Productionization Phases

### Phase 1: Environment Configuration (HIGH PRIORITY)

**Objective**: Support dev/test/production environments like other Planet Nine services

**Tasks:**

1. **Add Environment Detection** ✅ (Similar to Babelfish)
   - Support `NODE_ENV` environment variable (development, test, production)
   - Add `TEST_MODE` for development convenience
   - Log environment on startup

2. **Environment-Specific Configuration**
   ```javascript
   const config = {
     development: {
       PORT: 3010,
       BDO_BASE_URL: 'http://localhost:3003',
       CORS_ORIGIN: '*'
     },
     test: {
       PORT: 5125,
       BDO_BASE_URL: 'http://localhost:5114',
       CORS_ORIGIN: '*'
     },
     production: {
       PORT: 3010,
       BDO_BASE_URL: 'https://bdo.allyabase.com',
       CORS_ORIGIN: 'https://glyphenge.com'
     }
   };
   ```

3. **Update .env.example**
   ```bash
   NODE_ENV=production
   PORT=3010
   BDO_BASE_URL=https://bdo.allyabase.com
   CORS_ORIGIN=https://glyphenge.com
   ```

**Success Criteria:**
- Server logs environment on startup
- Different configs for dev/test/prod
- Environment switching via NODE_ENV

---

### Phase 2: Git Repository Setup (HIGH PRIORITY)

**Objective**: Get Glyphenge into version control

**Current State:** Glyphenge is NOT in git (similar to Babelfish)

**Tasks:**

1. **Initialize Repository**
   ```bash
   cd /Users/zachbabb/Work/planet-nine/the-advancement/glyphenge
   git init
   git add -A
   git commit -m "Initial Glyphenge implementation

   Features:
   - Server-side SVG rendering (3 templates)
   - POST /create endpoint with BDO integration
   - Emojicode generation for public access
   - Linktree import support
   - Sharon test suite (10 tests)
   - Docker deployment configuration
   - Client-side URL construction"
   ```

2. **Create .gitignore**
   ```
   node_modules/
   .env
   .env.local
   .DS_Store
   npm-debug.log*
   ```

3. **Push to GitHub**
   ```bash
   git remote add origin git@github.com:planet-nine-app/the-advancement.git
   git push -u origin main
   ```

**Success Criteria:**
- Glyphenge in git with clean history
- .gitignore prevents sensitive files
- Pushed to GitHub

---

### Phase 3: Ecosystem Integration (MEDIUM PRIORITY)

**Objective**: Add Glyphenge to allyabase Docker ecosystem

**Current Integration:** Glyphenge runs standalone, needs to join ecosystem

**Tasks:**

1. **Update allyabase Dockerfile**
   Add to `/allyabase/deployment/docker/Dockerfile`:
   ```dockerfile
   # Glyphenge - Link Tapestry Service
   WORKDIR /usr/src/app/the-advancement/glyphenge
   RUN npm install

   EXPOSE 3010
   ```

2. **Update ecosystem.config.js**
   Add to PM2 configuration in `start.sh`:
   ```javascript
   {
     name: 'glyphenge',
     script: '/usr/src/app/the-advancement/glyphenge/server.js',
     env: {
       LOCALHOST: 'true',
       PORT: '3010',
       BDO_BASE_URL: 'http://localhost:3003',
       NODE_ENV: 'production'
     }
   }
   ```

3. **Update Docker Port Mappings**
   Add to docker run commands:
   ```bash
   -p 3010:3010 \
   ```

4. **Test in Ecosystem**
   ```bash
   cd /path/to/allyabase/deployment/docker
   docker build -t planetnine/allyabase:latest .
   docker run -d --name planet-nine-ecosystem \
     -p 3010:3010 \
     [... other ports ...]
     planetnine/allyabase:latest

   # Verify Glyphenge running
   docker exec planet-nine-ecosystem pm2 list
   curl http://localhost:3010
   ```

**Success Criteria:**
- Glyphenge appears in PM2 list
- Accessible on port 3010 from host
- BDO integration works within container
- Sharon tests pass against ecosystem

---

### Phase 4: Production Deployment (HIGH PRIORITY)

**Objective**: Deploy Glyphenge to production server with SSL

**Infrastructure Needs:**

1. **Custom Domain Setup**
   - DNS A record: `glyphenge.com → [server IP]`
   - Or subdomain: `glyphenge.allyabase.com → [server IP]`

2. **SSL/TLS Configuration (Nginx)**
   Create `/etc/nginx/sites-available/glyphenge`:
   ```nginx
   server {
       listen 443 ssl http2;
       server_name glyphenge.com;

       ssl_certificate /etc/letsencrypt/live/glyphenge.com/fullchain.pem;
       ssl_certificate_key /etc/letsencrypt/live/glyphenge.com/privkey.pem;

       # Security headers
       add_header Strict-Transport-Security "max-age=31536000" always;
       add_header X-Frame-Options "SAMEORIGIN" always;
       add_header X-Content-Type-Options "nosniff" always;

       location / {
           proxy_pass http://localhost:3010;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
       }
   }

   # HTTP → HTTPS redirect
   server {
       listen 80;
       server_name glyphenge.com;
       return 301 https://$server_name$request_uri;
   }
   ```

3. **Let's Encrypt Certificate**
   ```bash
   sudo certbot --nginx -d glyphenge.com
   ```

4. **Update Production Config**
   ```bash
   # /etc/environment or .env file
   NODE_ENV=production
   BDO_BASE_URL=https://bdo.allyabase.com
   PORT=3010
   CORS_ORIGIN=https://glyphenge.com
   ```

**Success Criteria:**
- HTTPS access at glyphenge.com
- SSL certificate valid and auto-renewing
- All API calls work over HTTPS
- BDO integration uses production BDO service

---

### Phase 5: Monitoring and Observability (MEDIUM PRIORITY)

**Objective**: Production monitoring and error tracking

**Tasks:**

1. **PM2 Monitoring** (if in ecosystem)
   ```bash
   docker exec planet-nine-ecosystem pm2 monit
   docker exec planet-nine-ecosystem pm2 logs glyphenge
   ```

2. **Log Aggregation**
   ```javascript
   // Add structured logging to server.js
   const winston = require('winston');

   const logger = winston.createLogger({
     level: process.env.LOG_LEVEL || 'info',
     format: winston.format.json(),
     transports: [
       new winston.transports.File({ filename: 'error.log', level: 'error' }),
       new winston.transports.File({ filename: 'combined.log' })
     ]
   });

   // Replace console.log with logger
   logger.info('Glyphenge starting', { port: PORT, env: NODE_ENV });
   ```

3. **Health Check Endpoint**
   ```javascript
   app.get('/health', (req, res) => {
     res.json({
       status: 'healthy',
       version: '0.1.0',
       environment: process.env.NODE_ENV,
       uptime: process.uptime(),
       bdoConnected: !!bdoLib
     });
   });
   ```

4. **Error Tracking** (Optional - Sentry)
   ```javascript
   const Sentry = require('@sentry/node');

   Sentry.init({
     dsn: process.env.SENTRY_DSN,
     environment: process.env.NODE_ENV
   });

   app.use(Sentry.Handlers.requestHandler());
   app.use(Sentry.Handlers.errorHandler());
   ```

5. **Performance Metrics**
   - Track POST /create response times
   - Monitor BDO service latency
   - Count emojicodes generated
   - Track alphanumeric URL hits

**Success Criteria:**
- Logs aggregated and searchable
- Health endpoint returns correct status
- Errors tracked and reported
- Performance metrics available

---

### Phase 6: Security Hardening (HIGH PRIORITY)

**Objective**: Production security best practices

**Tasks:**

1. **Rate Limiting**
   ```javascript
   const rateLimit = require('express-rate-limit');

   const createLimiter = rateLimit({
     windowMs: 15 * 60 * 1000, // 15 minutes
     max: 10, // 10 tapestries per 15 minutes
     message: 'Too many tapestries created, please try again later.'
   });

   app.post('/create', createLimiter, async (req, res) => {
     // ... existing code
   });
   ```

2. **Input Validation**
   ```javascript
   const { body, validationResult } = require('express-validator');

   app.post('/create', [
     body('title').trim().isLength({ min: 1, max: 100 }),
     body('links').isArray({ min: 1, max: 20 }),
     body('links.*.title').trim().isLength({ min: 1, max: 50 }),
     body('links.*.url').isURL()
   ], async (req, res) => {
     const errors = validationResult(req);
     if (!errors.isEmpty()) {
       return res.status(400).json({ errors: errors.array() });
     }
     // ... existing code
   });
   ```

3. **CORS Configuration**
   ```javascript
   const cors = require('cors');

   const corsOptions = {
     origin: process.env.CORS_ORIGIN || '*',
     methods: ['GET', 'POST'],
     allowedHeaders: ['Content-Type'],
     credentials: true
   };

   app.use(cors(corsOptions));
   ```

4. **Helmet Security Headers**
   ```javascript
   const helmet = require('helmet');

   app.use(helmet({
     contentSecurityPolicy: {
       directives: {
         defaultSrc: ["'self'"],
         styleSrc: ["'self'", "'unsafe-inline'"],
         imgSrc: ["'self'", "data:", "https:"]
       }
     }
   }));
   ```

**Success Criteria:**
- Rate limiting prevents abuse
- Input validation blocks malicious data
- CORS properly configured
- Security headers present

---

### Phase 7: Documentation Updates (MEDIUM PRIORITY)

**Objective**: Complete production documentation

**Tasks:**

1. **Update README.md**
   - Add production deployment section
   - Document environment variables
   - Add troubleshooting guide
   - Include monitoring instructions

2. **Create DEPLOYMENT-GUIDE.md**
   - Step-by-step production deployment
   - SSL certificate setup
   - Nginx configuration
   - Docker ecosystem integration

3. **Update CLAUDE.md**
   - Current production status
   - Deployment history
   - Known limitations
   - Future roadmap

4. **API Documentation**
   - OpenAPI/Swagger spec for POST /create
   - Example requests and responses
   - Error codes and messages

**Success Criteria:**
- Documentation complete and accurate
- New team members can deploy
- All endpoints documented
- Troubleshooting guides available

---

### Phase 8: Performance Optimization (LOW PRIORITY)

**Objective**: Optimize for production load

**Tasks:**

1. **Caching Strategy**
   ```javascript
   const NodeCache = require('node-cache');
   const cache = new NodeCache({ stdTTL: 600 }); // 10 minutes

   // Cache BDO metadata
   app.get('/t/:identifier', async (req, res) => {
     const cacheKey = `bdo:${req.params.identifier}`;
     const cached = cache.get(cacheKey);

     if (cached) {
       return res.send(renderPage(cached));
     }

     // ... fetch from BDO
     cache.set(cacheKey, metadata);
   });
   ```

2. **SVG Optimization**
   ```javascript
   const SVGO = require('svgo');

   async function optimizeSVG(svgContent) {
     const result = await SVGO.optimize(svgContent, {
       plugins: [
         'removeDoctype',
         'removeComments',
         'cleanupNumericValues'
       ]
     });
     return result.data;
   }
   ```

3. **Connection Pooling**
   - BDO service connection pooling
   - Keep-alive headers
   - HTTP/2 support

4. **CDN Integration** (Future)
   - Serve static assets from CDN
   - Cache SVG tapestries
   - Edge caching for emojicodes

**Success Criteria:**
- Response times under 200ms
- BDO cache hit rate >80%
- SVG sizes reduced by 20%+
- Server handles 100+ concurrent users

---

## Priority Matrix

### Must Have (Before Production)
1. ✅ Git repository setup
2. ✅ Environment configuration
3. ✅ SSL/TLS setup
4. ✅ Security hardening (rate limiting, validation)
5. ✅ Monitoring and health checks

### Should Have (First Month)
6. Ecosystem integration (PM2, Docker)
7. Complete documentation
8. Error tracking (Sentry or similar)
9. Performance metrics

### Nice to Have (Future)
10. Caching optimization
11. CDN integration
12. Advanced analytics
13. A/B testing infrastructure

---

## Timeline Estimate

**Week 1:**
- Git repository setup (2 hours)
- Environment configuration (4 hours)
- Security hardening (6 hours)

**Week 2:**
- SSL/TLS deployment (4 hours)
- Ecosystem integration (8 hours)
- Monitoring setup (4 hours)

**Week 3:**
- Documentation updates (8 hours)
- Performance testing (4 hours)
- Bug fixes and polish (4 hours)

**Total:** ~44 hours (approximately 1.5 weeks of focused work)

---

## Success Metrics

### Technical Metrics
- [ ] 99.9% uptime
- [ ] <200ms average response time
- [ ] Zero data loss incidents
- [ ] All Sharon tests passing

### Business Metrics
- [ ] Tapestries created per day
- [ ] Emojicode shares
- [ ] Alphanumeric URL usage
- [ ] Linktree import conversions

### User Experience
- [ ] Zero SSL certificate errors
- [ ] Fast page loads (<1s)
- [ ] Mobile-friendly rendering
- [ ] Error messages helpful

---

## Risk Assessment

### High Risk
- **BDO Service Dependency**: Glyphenge requires BDO for storage
  - *Mitigation*: Health checks, circuit breaker pattern

- **SSL Certificate Expiry**: Let's Encrypt certs expire after 90 days
  - *Mitigation*: Automated renewal with certbot

### Medium Risk
- **Rate Limiting Too Aggressive**: Could block legitimate users
  - *Mitigation*: Start conservative, monitor, adjust based on usage

- **Emojicode Collisions**: 8-emoji codes could theoretically collide
  - *Mitigation*: BDO service handles uniqueness, log collisions

### Low Risk
- **SVG Rendering Issues**: Some SVGs might not display correctly
  - *Mitigation*: Input validation, SVG sanitization, error handling

---

## Rollback Plan

If production deployment fails:

1. **Revert to Previous Version**
   ```bash
   git revert [commit-hash]
   docker exec planet-nine-ecosystem pm2 restart glyphenge
   ```

2. **Restore Configuration**
   - Keep backup of .env files
   - Document all nginx changes
   - PM2 ecosystem.config.js in version control

3. **Communication**
   - Status page update
   - User notification if needed
   - Post-mortem document

---

## Next Steps

**Immediate (This Session):**
1. ✅ Create this productionization plan
2. Initialize git repository
3. Add environment configuration
4. Update documentation

**Next Session:**
1. SSL/TLS setup
2. Security hardening implementation
3. Ecosystem integration
4. Production deployment

**Following Sessions:**
1. Monitoring and observability
2. Performance optimization
3. Documentation completion

---

**Created:** January 12, 2025
**Status:** Planning Document
**Next Review:** After Phase 1 completion
