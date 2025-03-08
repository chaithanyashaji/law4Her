# Law4Her 🚀
**Empowering Women with Legal Assistance in India**

Law4Her is a comprehensive legal assistance platform designed to support women in India by providing access to legal information, consultations with verified lawyers, and a safe community to share experiences. The app integrates advanced AI capabilities to deliver accurate and multilingual legal support based on Indian Penal Code (IPC) and BNS (Bharatiya Nyaya Sanhita) datasets.

---

## 🌟 **Features**

### 🤖 AI-Powered Legal Chatbot
- **Datasets:** Supports both IPC and BNS, with an emphasis on BNS.
- **Multilingual Support:** Communicate in multiple Indian languages including Hindi, Malayalam, Tamil, Telugu, Kannada, Marathi, Gujarati, Punjabi, Bengali, and Urdu.
- **Advanced NLP:** Uses Mistral AI, and Nomic AI with Hugging Face embeddings.
- **Translation:** Powered by Google API for seamless language translation.
- **Encryption:** Ensures privacy with AES encryption for all chats.

---

### 👩‍⚖️ Lawyer Consultation
- **Verified Lawyers:** Connect with lawyers verified by Lawyer ID.
- **Payment Integration:** Uses Razorpay for paid consultations.
- **AES Encryption:** Secures all communications.
- **Session Timer:** Charges are deducted per minute during sessions.

---

### 🗣️ Anonymous Open Forum
- **Safe Space:** Share experiences and seek advice anonymously.
- **Moderation:** Includes reporting features to ensure a safe community.

---

### 🛠️ Admin Features
- **Lawyer Verification:** Approve or deny lawyer profiles based on ID.
- **Report Handling:** Manage reports from the open forum.
- **Earnings Dashboard:** View payment earnings from consultations.

---

### 🔍 AI and NLP Integration
- **LangChain:** For robust NLP and Retrieval-Augmented Generation (RAG).
- **Custom Prompt Templates:** Designed for legal queries.
- **FAISS Vector Database:** Efficient text chunk indexing and retrieval.
- **Web Scraping:** Uses Selenium to scrape legal content and convert it to JSON/CSV.

---

## 🎨 **Design and UI**
- **Built with:** Flutter.
- **Theme:**
  - **Light:** `#416d6d`, `#608e8e`, `#c5d0d3`.
  - **Dark:** `#1e1e2a`, `#7d444f`, `#44404d`.

---

## 🔒 **Security**
- **Encryption:** AES for chat security.
- **Authentication:** Google Authentication for users (except lawyers).
- **Data Storage:** Firebase for user data and chats.

---

## 🛠️ **Technologies Used**
- **Frontend:** Flutter
- **Backend:** FastAPI
- **Database:** Firebase
- **NLP:** LEGAL-BERT, Mistral AI, Nomic AI
- **Payments:** Razorpay
- **Hosting:** Hugging Face Spaces for AI model endpoints.

---

## 🔗 **Project Links**
- **Chatbot Demo:** [Law4Her Chatbot](https://huggingface.co/spaces/chaithanyashaji/lawforher)
- **BNS-Law4Her Dataset:** [BNS-Law4Her](https://huggingface.co/spaces/chaithanyashaji/BNS-Law4her)

---

## 🚀 **Getting Started**
### Prerequisites
- **Flutter SDK:** >= 2.17.0
- **Firebase CLI:** For backend integration.

### Installation
```bash
git clone https://github.com/chaithanyashaji/Law4Her.git
cd Law4Her
flutter pub get
