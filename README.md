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

## 📱 **Screenshots**

### 🔹 **Splash Screen**
![Splash Screen](https://github.com/user-attachments/assets/28af6a3d-aead-4c10-90de-00be58aa2bf2)

---

### 🔹 **User Home Screen**
![User Home Screen](https://github.com/user-attachments/assets/0027f998-c5b1-490b-9209-ae0ed7d517e1)

---

### 🔹 **User Profile**
![User Profile](https://github.com/user-attachments/assets/520f1193-2f77-4082-8525-73f33bbcb3b4)

---

### 🔹 **User Wallet**
![User Wallet](https://github.com/user-attachments/assets/9bde15ef-7298-44b0-8eb1-af0fe0bfdc91)

---

### 🔹 **Lawyer Home Screen**
![Lawyer Home Screen](https://github.com/user-attachments/assets/336f04d1-b616-40ab-8375-768d645b56a9)

---

### 🔹 **Lawyer Profile**
![Lawyer Profile](https://github.com/user-attachments/assets/57b2583d-acba-4858-8b63-cbdfd42a22bc)

---

### 🔹 **Lawyer Earnings**
![Lawyer Earnings](https://github.com/user-attachments/assets/61e96ce5-2b1a-403c-8396-be94d0a7982a)

---

### 🔹 **Lawyers List**
![Lawyers List](https://github.com/user-attachments/assets/b173b0ed-ddea-4460-8589-b5940ffe6bef)

---

### 🔹 **IPC Chatbot Screen**
![IPC Chatbot Screen](https://github.com/user-attachments/assets/68fbfe6c-0127-457d-9eda-3341cf0611ac)

---

### 🔹 **Difference Between IPC and BNS**
![Difference Between IPC and BNS](https://github.com/user-attachments/assets/dfe8b3c3-d5eb-42bd-a285-0f605947f534)

---

### 🔹 **Anonymous Forum**
![Anonymous Forum](https://github.com/user-attachments/assets/2476cc56-19b6-4c05-aeaf-97107719b714)

---

## 🔍 AI and NLP Integration
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
