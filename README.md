# 🌾 SmartHinga Crop Yield Prediction

[![Deployment Status](https://img.shields.io/badge/API-Live-brightgreen)](https://linear-regression-model-aef5.onrender.com/documentation/)
[![Flutter](https://img.shields.io/badge/Flutter-Mobile%20App-blue)](https://flutter.dev)
[![Machine Learning](https://img.shields.io/badge/ML-Random%20Forest-orange)](https://scikit-learn.org/)

## 🎯 Mission

Empowering farmers with **data-driven insights** to make informed agricultural decisions. This comprehensive solution combines machine learning predictions with an intuitive mobile application to optimize crop yields based on climatic and agricultural conditions, making small to medium-sized farming operations more productive and sustainable worldwide.

**Data Source:** [Kaggle](https://kaggle.com)

---

## 🎥 Demo

**Watch the project in action:**

[![YouTube Demo](https://img.shields.io/badge/YouTube-Demo%20Video-red?logo=youtube)](https://www.youtube.com/watch?v=rghuLB1MBS8)

---

## 🚀 Live Deployment

The **API is live and ready to use!**

🔗 **API Documentation:** [`https://linear-regression-model-aef5.onrender.com/documentation/`](https://linear-regression-model-aef5.onrender.com/documentation/)

---

## 📱 Getting Started with the Mobile App

### Prerequisites
- Flutter SDK (>=3.7.2)
- Android Studio / VS Code
- Git

### Quick Setup

```bash
# 1. Clone the repository
git clone https://github.com/MikeManzi/linear_regression_model.git

# 2. Navigate to the Flutter app directory
cd linear_regression_model/summative/flutterapp

# 3. Install dependencies
flutter pub get

# 4. Run the app
flutter run
```

### 📂 Project Structure

```
linear_regression_model/
├── 📊 linear_regression/          # ML model training & analysis
│   ├── crop_yield_prediction.ipynb
│   ├── crop_yield.csv
│   └── optimal_crop_yield_model.pkl
├── 🔧 summative/
│   ├── 🚀 api/                   # Flask REST API
│   │   ├── app.py
│   │   ├── requirements.txt
│   │   └── optimal_crop_yield_model.pkl.gz
│   └── 📱 flutterapp/            # Mobile application
│       ├── lib/
│       ├── pubspec.yaml
│       └── README.md
└── 📖 README.md
```
