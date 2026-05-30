# 🚀 Kepr App - Deployment Guide

## Production Build Status
✅ Build configuration files ready  
⏳ Web bundle building...

---

## **Deploy to Netlify (Easiest)**

### Step 1: Install Netlify CLI
```bash
npm install -g netlify-cli
```

### Step 2: Authenticate
```bash
netlify login
```

### Step 3: Deploy
```bash
cd c:/Users/purus/OneDrive/Documents/A/kepr
netlify deploy --prod --dir=build/web
```

✅ You'll get a URL like `https://kepr-app.netlify.app`

---

## **Deploy to Vercel (Alternative)**

### Step 1: Install Vercel CLI
```bash
npm install -g vercel
```

### Step 2: Deploy
```bash
cd c:/Users/purus/OneDrive/Documents/A/kepr
vercel --prod
# Select default settings
```

✅ You'll get a URL like `https://kepr-app.vercel.app`

---

## **Set Environment Variables**

Both Netlify & Vercel require you to set:

### Netlify Dashboard:
1. Go to Site Settings → Build & Deploy → Environment
2. Add variables:
   - `SUPABASE_URL` = `https://upzosakzkhgwkhungifq.supabase.co`
   - `SUPABASE_ANON_KEY` = `<your-actual-key>`

### Vercel Dashboard:
1. Go to Settings → Environment Variables
2. Add same variables as above

---

## **Security Checklist Before Going Live**

- [ ] Replace `SUPABASE_ANON_KEY` with real key in deployment platform
- [ ] Enable Supabase RLS policies (run `supabase_schema.sql`)
- [ ] Set up custom domain (optional)
- [ ] Enable HTTPS (automatic on both platforms)
- [ ] Add CORS rules in Supabase
- [ ] Test on production URL before announcing

---

## **After Deployment**

1. **Test the app**: Click the generated URL
2. **Check console**: Open DevTools (F12) for any errors
3. **Verify Supabase connection**: Try creating a property
4. **Set custom domain** (optional):
   - Netlify: Domain Settings → Custom Domain
   - Vercel: Settings → Domains

---

## **Rollback/Delete**

- **Netlify**: `netlify delete`
- **Vercel**: `vercel --prod --archive`

---

## **Next Steps**

1. Complete the build: `../flutter/bin/flutter.bat build web --release`
2. Choose Netlify or Vercel
3. Run deployment command
4. Share your public URL! 🎉
