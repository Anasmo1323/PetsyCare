import os
import numpy as np
from flask import Flask, request, jsonify
from PIL import Image



# --- TENSORFLOW IMPORTS ---
import tensorflow as tf
from tensorflow.keras.applications.mobilenet_v2 import MobileNetV2, preprocess_input, decode_predictions
from tensorflow.keras.preprocessing.image import img_to_array

app = Flask(__name__)

# 1. LOAD THE MODEL (We do this once when server starts)
print("⏳ Loading ML Model... this may take a moment.")
# MobileNetV2 is fast, lightweight, and knows 120+ dog breeds
model = MobileNetV2(weights='imagenet')
print("✅ Model Loaded!")

@app.route('/predict', methods=['POST'])
def predict():
    if 'file' not in request.files:
        return jsonify({"error": "No file uploaded"}), 400
    
    file = request.files['file']
    
    try:
        # 2. PRE-PROCESS IMAGE
        # Open image directly from memory
        img = Image.open(file.stream)
        
        # Resize to 224x224 (Standard for MobileNet/ResNet)
        img = img.resize((224, 224))
        
        # Convert to array and add batch dimension (1, 224, 224, 3)
        img_array = img_to_array(img)
        img_array = np.expand_dims(img_array, axis=0)
        
        # Preprocess (Scale pixel values to -1 to 1)
        img_array = preprocess_input(img_array)

        # 3. INFERENCE (Run the Model)
        predictions = model.predict(img_array)
        
        # 4. DECODE RESULTS
        # get top 1 result: [(class_id, class_name, confidence)]
        decoded = decode_predictions(predictions, top=1)[0][0]
        
        result_name = decoded[1].replace('_', ' ').title() # e.g. "Golden Retriever"
        result_confidence = float(decoded[2])

        print(f"🧠 AI saw: {result_name} ({result_confidence:.2%})")

        return jsonify({
            "label": result_name,
            "confidence": result_confidence
        })

    except Exception as e:
        print(f"❌ Error during inference: {e}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    # host='0.0.0.0' makes it accessible on your local network
    app.run(host='0.0.0.0', port=5000, debug=False)