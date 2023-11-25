#! /bin/bash

function delete_sagemaker_domain_apps () {
    region=$1
    
    apps=$(aws sagemaker list-apps --region $region \
        --query 'Apps[?Status==`InService`]')
    
    echo $apps | jq -c '.[]' | while read app; do
        domainId=$(echo $app | jq -r '.DomainId')
        userProfileName=$(echo $app | jq -r '.UserProfileName')
        appType=$(echo $app | jq -r '.AppType')
        appName=$(echo $app | jq -r '.AppName')
        echo "Deleting app: ${domainId}-${userProfileName}-${appType}-${appName}"; 
        aws sagemaker delete-app --region $region \
            --domain-id $domainId \
            --user-profile-name $userProfileName  \
            --app-type $appType \
            --app-name $appName
    done
}

function delete_sagemaker_model_endpoints () {
    region=$1
    
    endpoints=$(aws sagemaker list-endpoints --region $region | jq -r '.Endpoints[] | .EndpointName')
    for endpoint in $endpoints; 
    do 
        echo "Deleting endpoint: ${endpoint}"; 
        aws sagemaker delete-endpoint --endpoint-name $endpoint --region $region; 
    done
    
    endpoint_configs=$(aws sagemaker list-endpoint-configs --region $region | jq -r '.EndpointConfigs[] | .EndpointConfigName')
    for endpoint_config in $endpoint_configs; 
    do 
        echo "Deleting endpoint config: ${endpoint_config}"; 
        aws sagemaker delete-endpoint-config --endpoint-config-name $endpoint_config --region $region; 
    done
    
    models=$(aws sagemaker list-models --region $region | jq -r '.Models[] | .ModelName')
    for model in $models; 
    do 
        echo "Deleting model: ${model}"; 
        aws sagemaker delete-model --model-name $model --region $region; 
    done 
    
} 

function process_region() {
    region=$1
    echo "processing $region"
    delete_sagemaker_model_endpoints $region
    delete_sagemaker_domain_apps $region
} 

echo "Begin SageMaker cleanup"
# Parse through all regions. #TODO limit to sagemaker supported regions
regions=$(aws ec2 describe-regions | jq -r '.Regions[] | .RegionName')
for region in $regions; do process_region $region; done
echo "End SageMaker cleanup"

