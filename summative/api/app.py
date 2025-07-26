import gzip
import pickle
import pandas as pd
from flask import Flask
from flask_restx import Api, Resource, fields
from flask_cors import CORS


flask_application = Flask(__name__)
CORS(flask_application, origins=["*"])  # Enable cross-origin requests from any domain

# Configure Flask-RESTX API with comprehensive documentation
crop_yield_api = Api(
    flask_application,
    title='Crop Yield Prediction API',
    version='1.0.1',
    description='''
    🌾 Advanced Machine Learning API for Agricultural Yield Prediction
    
    This API provides accurate crop yield predictions based on environmental factors,
    soil conditions, and agricultural practices. Built using state-of-the-art 
    machine learning algorithms trained on comprehensive agricultural datasets.
    
    **Key Features:**
    - Multi-factor yield prediction (weather, soil, crop type, farming practices)
    - Real-time inference with optimized model performance
    - Comprehensive input validation and error handling
    - RESTful design with automatic documentation
    
    **Supported Prediction Factors:**
    - Geographic regions and climate zones
    - Soil types and characteristics
    - Crop varieties and species
    - Weather conditions and rainfall patterns
    - Temperature ranges and seasonal variations
    - Agricultural practices (fertilization, irrigation)
    - Growing periods and harvest timing
    ''',
    doc='/documentation/',  # Custom documentation endpoint
    contact='Agricultural Technology Team',
    license='MIT License'
)

# Create namespace for prediction operations
prediction_namespace = crop_yield_api.namespace(
    'yield-prediction', 
    description='🎯 Crop Yield Prediction Operations',
    path='/api/v2'
)

# ============================
# MODEL LOADING AND SETUP
# ============================

def initialize_prediction_model():
    """
    Load the trained machine learning model and associated encoders from compressed file.
    
    Returns:
    --------
    dict: Complete model package including trained model and categorical encoders
    
    Raises:
    -------
    FileNotFoundError: If model file is not found
    pickle.UnpicklingError: If model file is corrupted
    """
    try:
        with gzip.open('optimal_crop_yield_model.pkl.gz', 'rb') as model_file:
            complete_model_package = pickle.load(model_file)
        return complete_model_package
    except FileNotFoundError:
        raise FileNotFoundError("Model file 'optimal_crop_yield_model.pkl.gz' not found. Please ensure the model is trained and saved.")
    except Exception as e:
        raise Exception(f"Error loading model: {str(e)}")

print("🔄 Loading trained crop yield prediction model...")
complete_model_data = initialize_prediction_model()

trained_ml_model = complete_model_data['model']
geographic_region_encoder = complete_model_data['region_encoder'] 
soil_type_encoder = complete_model_data['soil_encoder']          
crop_variety_encoder = complete_model_data['crop_encoder']       
weather_condition_encoder = complete_model_data['weather_encoder']

print(f"✅ Model loaded successfully: {complete_model_data.get('model_name', 'Unknown Model')}")

agricultural_input_schema = crop_yield_api.model('CropYieldPredictionInput', {
    'Region': fields.String(
        required=True, 
        description='🌍 Geographic region where the crop is cultivated',
        example='North',
        help='Supported regions: North, South, East, West, Central'
    ),
    'Soil_Type': fields.String(
        required=True, 
        description='🏔️ Classification of soil composition and characteristics',
        example='Loam',
        help='Common soil types: Clay, Sandy, Loam, Silt, Peat'
    ),
    'Crop': fields.String(
        required=True, 
        description='🌾 Type of crop being cultivated',
        example='Wheat',
        help='Supported crops: Wheat, Rice, Corn, Barley, Soybean, etc.'
    ),
    'Rainfall_mm': fields.Float(
        required=True, 
        description='🌧️ Total rainfall amount during growing season (millimeters)',
        example=450.5,
        min=0,
        help='Typical range: 200-2000mm depending on crop and region'
    ),
    'Temperature_Celsius': fields.Float(
        required=True, 
        description='🌡️ Average temperature during growing period (Celsius)',
        example=22.5,
        min=-10,
        max=50,
        help='Optimal range varies by crop: 15-30°C for most temperate crops'
    ),
    'Fertilizer_Used': fields.String(
        required=True, 
        description='🧪 Whether chemical or organic fertilizers were applied',
        example='TRUE',
        enum=['TRUE', 'FALSE', 'true', 'false'],
        help='Boolean indicator: TRUE/FALSE (case insensitive)'
    ),
    'Irrigation_Used': fields.String(
        required=True, 
        description='💧 Whether artificial irrigation systems were employed',
        example='FALSE',
        enum=['TRUE', 'FALSE', 'true', 'false'],
        help='Boolean indicator: TRUE/FALSE (case insensitive)'
    ),
    'Weather_Condition': fields.String(
        required=True, 
        description='☀️ Predominant weather pattern during growing season',
        example='Sunny',
        help='Common conditions: Sunny, Rainy, Cloudy, Stormy, Mild'
    ),
    'Days_to_Harvest': fields.Integer(
        required=True, 
        description='📅 Number of days from planting to harvest',
        example=120,
        min=30,
        max=365,
        help='Typical growing periods: 90-150 days for most crops'
    )
})

prediction_response_schema = crop_yield_api.model('CropYieldPredictionResponse', {
    'predicted_yield_tons_per_hectare': fields.Float(
        description='🎯 Predicted crop yield in tons per hectare',
        example=4.25
    ),
    'confidence_level': fields.String(
        description='📊 Model confidence assessment',
        example='High'
    ),
    'model_version': fields.String(
        description='🔧 Version of the prediction model used',
        example='2.0.1'
    ),
    'processing_time_ms': fields.Float(
        description='⚡ Time taken to process the prediction (milliseconds)',
        example=15.8
    )
})

error_response_schema = crop_yield_api.model('ErrorResponse', {
    'error_message': fields.String(
        description='❌ Detailed error description',
        example='Invalid input: Region not recognized'
    ),
    'error_code': fields.String(
        description='🔍 Specific error classification',
        example='VALIDATION_ERROR'
    ),
    'suggestions': fields.List(
        fields.String,
        description='💡 Helpful suggestions to resolve the error',
        example=['Check region spelling', 'Use supported region names']
    )
})

def transform_agricultural_input(raw_input_data):
    """
    Comprehensive preprocessing pipeline for agricultural input data.
    
    This function handles:
    - Data format standardization
    - Categorical variable encoding
    - Boolean feature conversion
    - Input validation and cleaning
    
    Parameters:
    -----------
    raw_input_data : dict or pandas.DataFrame
        Raw input data containing agricultural parameters
        
    Returns:
    --------
    pandas.DataFrame: Processed feature matrix ready for model prediction
    
    Raises:
    -------
    ValueError: If categorical values are not recognized by encoders
    KeyError: If required features are missing
    """
    
    if isinstance(raw_input_data, dict):
        processed_dataframe = pd.DataFrame([raw_input_data])
    else:
        processed_dataframe = raw_input_data.copy()
    
    
    text_features_to_standardize = ['Region', 'Soil_Type', 'Crop', 'Weather_Condition']
    for feature_name in text_features_to_standardize:
        processed_dataframe[feature_name] = processed_dataframe[feature_name].str.strip().str.title()
    
    
    try:
        processed_dataframe['Region'] = geographic_region_encoder.transform(processed_dataframe['Region'])
        processed_dataframe['Soil_Type'] = soil_type_encoder.transform(processed_dataframe['Soil_Type'])
        processed_dataframe['Crop'] = crop_variety_encoder.transform(processed_dataframe['Crop'])
        processed_dataframe['Weather_Condition'] = weather_condition_encoder.transform(processed_dataframe['Weather_Condition'])
    except ValueError as encoding_error:
        raise ValueError(f"Categorical encoding failed: {str(encoding_error)}. Please check that all categorical values are supported.")
    
    boolean_feature_mapping = {'TRUE': 1, 'FALSE': 0}
    
    processed_dataframe['Fertilizer_Used'] = (
        processed_dataframe['Fertilizer_Used']
        .astype(str)
        .str.upper()
        .str.strip()
        .map(boolean_feature_mapping)
    )
    
    processed_dataframe['Irrigation_Used'] = (
        processed_dataframe['Irrigation_Used']
        .astype(str)
        .str.upper()
        .str.strip()
        .map(boolean_feature_mapping)
    )
    
    if processed_dataframe['Fertilizer_Used'].isna().any() or processed_dataframe['Irrigation_Used'].isna().any():
        raise ValueError("Boolean features must be 'TRUE' or 'FALSE' (case insensitive)")
    
    
    required_feature_columns = [
        'Region', 'Soil_Type', 'Crop', 'Rainfall_mm', 'Temperature_Celsius',
        'Fertilizer_Used', 'Irrigation_Used', 'Weather_Condition', 'Days_to_Harvest'
    ]
    
    feature_matrix = processed_dataframe[required_feature_columns]
    
    return feature_matrix

def calculate_prediction_confidence(prediction_value):
    """
    Assess confidence level of the prediction based on value ranges.
    
    Parameters:
    -----------
    prediction_value : float
        The predicted yield value
        
    Returns:
    --------
    str: Confidence level assessment
    """
    if 0 <= prediction_value <= 10:
        return "High"
    elif 10 < prediction_value <= 20:
        return "Medium"
    else:
        return "Low"

@prediction_namespace.route('/predict-yield')
class CropYieldPredictor(Resource):
    """
    🎯 Advanced Crop Yield Prediction Endpoint
    
    This endpoint provides comprehensive crop yield predictions using a trained
    machine learning model that considers multiple agricultural and environmental factors.
    """
    
    @prediction_namespace.doc('generate_crop_yield_prediction')
    @prediction_namespace.expect(agricultural_input_schema, validate=True)
    def post(self):
        """
        🌾 Generate Crop Yield Prediction
        
        Analyzes agricultural inputs and environmental conditions to predict crop yield
        using advanced machine learning algorithms. The prediction considers multiple
        factors including climate, soil conditions, crop variety, and farming practices.
        
        **Process Flow:**
        1. Validate and standardize input data
        2. Apply categorical encoding and preprocessing
        3. Generate prediction using trained ML model
        4. Calculate confidence assessment
        5. Return comprehensive prediction results
        
        **Example Usage:**
        ```json
        {
            "Region": "North",
            "Soil_Type": "Loam",
            "Crop": "Wheat",
            "Rainfall_mm": 450.5,
            "Temperature_Celsius": 22.5,
            "Fertilizer_Used": "TRUE",
            "Irrigation_Used": "FALSE",
            "Weather_Condition": "Sunny",
            "Days_to_Harvest": 120
        }
        ```
        """
        import time
        start_processing_time = time.time()
        
        try:
            agricultural_input_data = crop_yield_api.payload
            
            if not agricultural_input_data:
                return {
                    'error_message': 'No input data provided in request body',
                    'error_code': 'MISSING_DATA',
                    'suggestions': [
                        'Include all required agricultural parameters in JSON format',
                        'Refer to the API documentation for input schema'
                    ]
                }, 400
            
            required_fields = ['Region', 'Soil_Type', 'Crop', 'Rainfall_mm', 'Temperature_Celsius',
                             'Fertilizer_Used', 'Irrigation_Used', 'Weather_Condition', 'Days_to_Harvest']
            
            missing_fields = [field for field in required_fields if field not in agricultural_input_data]
            if missing_fields:
                return {
                    'error_message': f'Missing required fields: {", ".join(missing_fields)}',
                    'error_code': 'MISSING_FIELDS',
                    'suggestions': [
                        f'Include the following fields: {", ".join(missing_fields)}',
                        'Check the API documentation for complete field requirements'
                    ]
                }, 400
            
            processed_feature_matrix = transform_agricultural_input(agricultural_input_data)
            
            raw_prediction_result = trained_ml_model.predict(processed_feature_matrix)[0]
            
            final_prediction = max(0, float(raw_prediction_result))
            
            processing_duration = (time.time() - start_processing_time) * 1000
            confidence_assessment = calculate_prediction_confidence(final_prediction)
            
            result = {
                'predicted_yield_tons_per_hectare': round(final_prediction, 3),
                'confidence_level': confidence_assessment,
                'model_version': complete_model_data.get('model_name', 'AgriTech ML Model v2.0'),
                'processing_time_ms': round(processing_duration, 2)
            }
            print(f"DEBUG: Prediction result: {result}")  # Debug line
            return result, 200
            
        except ValueError as validation_error:
            return {
                'error_message': f'Input validation failed: {str(validation_error)}',
                'error_code': 'VALIDATION_ERROR',
                'suggestions': [
                    'Check that categorical values are supported by the model',
                    'Ensure boolean fields use TRUE/FALSE values',
                    'Verify numerical ranges are realistic'
                ]
            }, 422
            
        except Exception as unexpected_error:
            return {
                'error_message': f'Prediction processing failed: {str(unexpected_error)}',
                'error_code': 'PROCESSING_ERROR',
                'suggestions': [
                    'Verify input data format and values',
                    'Contact support if the error persists',
                    'Check API documentation for troubleshooting'
                ]
            }, 500

@prediction_namespace.route('/model-info')
class ModelInformation(Resource):
    """📊 Model Information and Health Check Endpoint"""
    
    @prediction_namespace.doc('get_model_information')
    def get(self):
        """
        📈 Retrieve Model Information and Health Status
        
        Provides comprehensive information about the loaded machine learning model,
        including version details, supported features, and system health status.
        """
        try:
            # Get supported categorical values from encoders
            supported_regions = geographic_region_encoder.classes_.tolist()
            supported_soil_types = soil_type_encoder.classes_.tolist()
            supported_crops = crop_variety_encoder.classes_.tolist()
            supported_weather_conditions = weather_condition_encoder.classes_.tolist()
            
            return {
                'model_status': 'Active and Ready',
                'model_name': complete_model_data.get('model_name', 'AgriTech ML Model'),
                'model_version': '2.0.1',
                'training_date': complete_model_data.get('training_date', 'Unknown'),
                'supported_features': {
                    'regions': supported_regions,
                    'soil_types': supported_soil_types,
                    'crops': supported_crops,
                    'weather_conditions': supported_weather_conditions
                },
                'api_version': '2.0.1',
                'health_status': '✅ Operational'
            }, 200
            
        except Exception as error:
            return {
                'error_message': f'Unable to retrieve model information: {str(error)}',
                'error_code': 'MODEL_INFO_ERROR'
            }, 500

@flask_application.route('/', methods=['GET'])
def api_root_endpoint():
    """🏠 API Root Endpoint - Health Check and Basic Information"""
    return {
        'service_name': 'AgriTech Crop Yield Prediction API',
        'version': '2.0.1',
        'status': '🟢 Operational',
        'description': 'Advanced machine learning API for agricultural yield prediction',
        'documentation_url': '/documentation/',
        'health_check': '✅ All systems operational',
        'supported_operations': [
            'POST /api/v2/predict-yield - Generate crop yield predictions',
            'GET /api/v2/model-info - Retrieve model information',
            'GET /documentation/ - Access API documentation'
        ]
    }, 200

if __name__ == '__main__':
    import os

    server_port = int(os.environ.get('PORT', 5000))
    debug_mode = os.environ.get('FLASK_ENV') == 'development'
    
    print("🚀 Starting AgriTech Crop Yield Prediction API...")
    print(f"📡 Server will run on port: {server_port}")
    print(f"🔧 Debug mode: {'Enabled' if debug_mode else 'Disabled'}")
    print(f"📚 API Documentation: http://localhost:{server_port}/documentation/")
    
    flask_application.run(
        host='0.0.0.0',
        port=server_port,
        debug=debug_mode,
        threaded=True
    )