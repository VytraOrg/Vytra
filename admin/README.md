# LocalCommerce Admin Portal

A premium, glassmorphic Single Page Application for administrators to review, approve, or reject business document uploads (GST Certificate and Trade License) from shopkeepers.

## Features
* **Admin Login**: Secure authentication with JWT.
* **Document Review**: Click to view high-resolution uploaded images or PDFs directly in a beautiful preview modal.
* **Status Controls**: Approve (verify) or Reject verification requests with confirmations.
* **Live Counts**: Dynamic metrics for Pending, Approved, Rejected, and Total shops.
* **Search & Filters**: Instantly find shops by name, owner email, or status.

## How to Run

### Option 1: Direct Browser Launch (Easiest)
Simply double-click the [index.html](file:///c:/Users/sayan/StudioProjects/LocalCommerceApp/admin/index.html) file to open it in your web browser. 

* **Local Backend Mode**: If you are running the backend locally (`npm run dev` on `http://localhost:5001`), the portal will automatically connect to it.
* **Cloud Backend Mode**: If accessed outside localhost, it will automatically route API requests to your live Render instance (`https://localcommerceapp-1.onrender.com`).

### Option 2: Live Server (VS Code / Python)
If you want to run it via a local static web server:

**Using Python:**
```bash
# From the admin directory:
python -m http.server 8080
```
Then visit `http://localhost:8080` in your browser.

## Credentials
To log in, use any user account that has the **`Admin`** role:
* **Role**: Admin
* **Request Format**: The portal sends `role: "Admin"` along with the email and password to ensure secure authorization.
