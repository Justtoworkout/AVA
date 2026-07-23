# Deploy Webhook to Vercel (100% Free, Zero Cold Starts)

Deploying to Vercel fixes the cold start issues. Follow these steps:

### Step 1: Push changes to GitHub
Add and push the new files to your GitHub repository:
```cmd
git add backend/vercel.json backend/api/vapiWebhook.js
git commit -m "Add Vercel configuration"
git push origin main
```

---

### Step 2: Deploy on Vercel
1. Go to [Vercel.com](https://vercel.com/) and sign up / log in with your GitHub account.
2. Click **Add New** → **Project**.
3. Import your **`AVA`** repository.
4. Set the **Root Directory** configuration to `backend`.
5. Click **Deploy**.

---

### Step 3: Configure Vapi Webhook URL
Once deployed, Vercel will give you a domain link (e.g. `https://ava-hospital.vercel.app`).

Paste the webhook URL into your **Vapi Dashboard** under **Server URL**:
`https://your-vercel-domain-link.vercel.app/vapiWebhook`
