import sys
import os
from dotenv import load_dotenv
load_dotenv()

from cloud_providers import get_cloud_provider

def print_usage():
    print("Usage: python stop_server.py <identifier> [cloud_provider] [resource_group/region] [--verbose]")
    print("  identifier:     Server name or instance ID")
    print("  cloud_provider: Optional - 'azure' or 'aws' (default is 'azure')")
    print("  resource_group: Optional - For Azure only, resource group name")
    print("  region:         Optional - AWS region or Azure location")
    print("  --verbose:      Optional - Enable verbose debug output")
    sys.exit(1)

def main():
    # Parse arguments
    if len(sys.argv) < 2:
        print_usage()
    
    # Check if verbose flag is provided
    verbose = "--verbose" in sys.argv
    if verbose:
        print(f"[VERBOSE] Running stop_server.py with arguments: {sys.argv}")
        print(f"[VERBOSE] Current working directory: {os.getcwd()}")
        # Remove verbose flag from args for further processing
        sys.argv.remove("--verbose")
    
    instance_id = sys.argv[1]
    cloud_provider_name = sys.argv[2] if len(sys.argv) > 2 else 'azure'
    
    if verbose:
        print(f"[VERBOSE] Instance ID: {instance_id}")
        print(f"[VERBOSE] Cloud provider: {cloud_provider_name}")
        
        # Debug environment variables
        if cloud_provider_name.lower() == 'azure':
            azure_client_id = os.getenv('AZURE_CLIENT_ID')
            azure_tenant_id = os.getenv('AZURE_TENANT_ID')
            azure_subscription_id = os.getenv('AZURE_SUBSCRIPTION_ID')
            azure_resource_group = os.getenv('AZURE_RESOURCE_GROUP')
            
            print(f"[VERBOSE] AZURE_CLIENT_ID exists: {bool(azure_client_id)}")
            print(f"[VERBOSE] AZURE_TENANT_ID exists: {bool(azure_tenant_id)}")
            print(f"[VERBOSE] AZURE_SUBSCRIPTION_ID exists: {bool(azure_subscription_id)}")
            print(f"[VERBOSE] AZURE_RESOURCE_GROUP exists: {bool(azure_resource_group)}")
    
    # Get additional parameters
    kwargs = {}
    if len(sys.argv) > 3 and cloud_provider_name.lower() == 'azure':
        kwargs['resource_group'] = sys.argv[3]
        if verbose:
            print(f"[VERBOSE] Using resource group: {kwargs['resource_group']}")
    if len(sys.argv) > 3 and cloud_provider_name.lower() == 'aws':
        kwargs['region'] = sys.argv[3]
        if verbose:
            print(f"[VERBOSE] Using region: {kwargs['region']}")
    
    try:
        # Initialize cloud provider
        if verbose:
            print(f"[VERBOSE] Initializing cloud provider: {cloud_provider_name}")
        
        cloud_provider = get_cloud_provider(cloud_provider_name)
        
        if verbose:
            print(f"[VERBOSE] Cloud provider initialized successfully")
        
        # Check current status
        if verbose:
            print(f"[VERBOSE] Checking current instance status")
            
        status = cloud_provider.check_instance_status(instance_id, **kwargs)
        print(f"Instance {instance_id} current status: {status}")
        
        # Stop the instance
        if verbose:
            print(f"[VERBOSE] Attempting to stop instance {instance_id}")
            
        if cloud_provider.stop_instance(instance_id, **kwargs):
            print(f"Successfully initiated stop for instance {instance_id}")
            
            # For AWS, wait for the instance to fully stop before returning
            if cloud_provider_name.lower() == 'aws':
                if verbose:
                    print(f"[VERBOSE] Waiting for AWS instance to fully stop")
                    
                print("Waiting for AWS instance to fully stop...")
                if cloud_provider.wait_for_stopped_status(instance_id, **kwargs):
                    print(f"AWS instance {instance_id} has fully stopped")
                    sys.exit(0)
                else:
                    print(f"Timeout waiting for AWS instance {instance_id} to stop")
                    sys.exit(1)
            
            sys.exit(0)
        else:
            print(f"Instance {instance_id} could not be stopped")
            sys.exit(1)
            
    except Exception as e:
        print(f"Error stopping instance: {e}")
        if verbose:
            import traceback
            print(f"[VERBOSE] Exception traceback: {traceback.format_exc()}")
        sys.exit(1)

if __name__ == "__main__":
    main()