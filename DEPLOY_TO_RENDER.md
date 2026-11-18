# How to Deploy Backend to Render (100% Free & 24/7 Live)
## बैकएंड को Render पर 24/7 लाइव होस्ट करने की सरल गाइड

Render (render.com) दुनिया का सबसे लोकप्रिय और भरोसेमंद **फ्री क्लाउड होस्टिंग प्लेटफॉर्म** है। इस पर आपका Laravel API 24 घंटे लगातार बिना लैपटॉप चालू रखे चलता रहेगा।

---

## 🎯 Render पर बैकएंड लाइव करने के 3 आसान स्टेप्स:

### स्टेप 1: कोड को अपने GitHub पर Push करें

यदि आपका प्रोजेक्ट पहले से GitHub पर नहीं है:
1. [GitHub.com](https://github.com) पर जाएं और एक नया Repository बनाएं (जैसे: `prakash_homiyopathik`).
2. अपने टर्मिनल में ये कमांड्स चलाएं:
   ```bash
   git remote add origin https://github.com/YOUR_USERNAME/prakash_homiyopathik.git
   git branch -M main
   git push -u origin main
   ```

---

### स्टेप 2: Render.com पर फ्री सर्विस बनाएं

1. [https://dashboard.render.com](https://dashboard.render.com) पर जाएं और फ्री अकाउंट में लॉगिन करें।
2. ऊपर दाईं ओर **"New +"** बटन पर क्लिक करें और **"Web Service"** चुनें।
3. **"Build and deploy from a Git repository"** पर क्लिक करें और अपना GitHub Repository (`prakash_homiyopathik`) कनेक्ट करें।
4. निम्नलिखित सेटिंग्स भरें:
   - **Name:** `prakash-homeo-api`
   - **Root Directory:** `backend`
   - **Environment / Runtime:** `Docker` (चूंकि हमने Dockerfile पहले ही बना दी है)
   - **Region:** Oregon (US West) या Singapore
   - **Branch:** `main`
   - **Instance Type:** **Free** ($0/month)
5. **"Deploy Web Service"** बटन पर क्लिक करें।

Render 2-3 मिनट में Docker इमेज बनाकर आपका API सर्वर लाइव कर देगा और आपको एक पब्लिक HTTPS लिंक देगा:
👉 **`https://prakash-homeo-api.onrender.com`**

---

### स्टेप 3: ऐप में Render का URL सेट करें

जैसे ही Render से आपका लिंक मिल जाए:
1. अपनी लाइव वेबसाइट **[https://prakash-homeo-hall-fatehpur.web.app](https://prakash-homeo-hall-fatehpur.web.app)** खोलें।
2. ऊपर दाईं ओर दिए गए **Settings (Gear Icon)** पर क्लिक करें।
3. अपना Render URL डालें:
   `https://prakash-homeo-api.onrender.com/api`
4. **"Test Server Connection"** दबाएं और **"Save & Apply"** पर क्लिक करें!

अब आपका पूरा क्लिनिक सिस्टम — पेशेंट बुकिंग, डॉक्टर डैशबोर्ड, रिसेप्शन डेस्क और लाइव टीवी डिस्प्ले — 24/7 इंटरनेट पर लाइव काम करेगा!

---

## ⚡ वर्तमान में एक्टिव लाइव टनल (Instant Access)
Render पर डिप्लॉय करने से पहले तुरंत टेस्ट करने हेतु वर्तमान में लाइव टनल सक्रिय है:
- **Active Live API:** `https://steep-yonder-blemish.ngrok-free.dev/api`
- **Firebase Web App:** `https://prakash-homeo-hall-fatehpur.web.app`
