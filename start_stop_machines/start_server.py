import sys
import os
import time
from dotenv import load_dotenv
load_dotenv()

from cloud_providers import get_cloud_provider

def print_usage():
    print("Usage: python start_server.py <identifier> [cloud_provider] [resource_group/region] [--verbose]")
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
        print(f"[VERBOSE] Running start_server.py with arguments: {sys.argv}")
        print(f"[VERBOSE] Current working directory: {os.getcwd()}")
        # Remove verbose flag from args for further processing
        sys.argv.remove("--verbose")
    
    instance_id = sys.argv[1]
    cloud_provider_name = sys.argv[2] if len(sys.argv) > 2 else 'azure'
    
    if verbose:
        print(f"[VERBOSE] Instance ID: {instance_id}")
        print(f"[VERBOSE] Cloud provider: {cloud_provider_name}")
        
        # Debug environment variables
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
        
        # Get current status to check for problematic states first
        if verbose:
            print(f"[VERBOSE] Checking current instance status")
        
        current_status = cloud_provider.check_instance_status(instance_id, **kwargs)
        print(f"Current status of {instance_id}: {current_status}")
        
        if current_status == 'stopping':
            print(f"ERROR: Instance {instance_id} is currently stopping. Please wait for it to fully stop before starting.")
            sys.exit(2)  # Using a special exit code for this case
        
        # Start the instance
        try:
            if verbose:
                print(f"[VERBOSE] Attempting to start instance {instance_id}")
            
            started = cloud_provider.start_instance(instance_id, **kwargs)
            
            if started:
                # Wait for instance to be in running state
                if verbose:
                    print(f"[VERBOSE] Instance start initiated, waiting for running status")
                
                if cloud_provider.wait_for_running_status(instance_id, **kwargs):
                    print(f"Instance {instance_id} is now running and ready")
                    sys.exit(0)
                else:
                    print(f"Timeout waiting for instance {instance_id} to be ready")
                    sys.exit(1)
            else:
                print(f"Could not start instance {instance_id}")
                sys.exit(1)
        except ValueError as ve:
            # Handle specific ValueError from our cloud provider
            print(f"ERROR: {ve}")
            sys.exit(2)
            
    except Exception as e:
        print(f"Error starting instance: {e}")
        if verbose:
            import traceback
            print(f"[VERBOSE] Exception traceback: {traceback.format_exc()}")
        sys.exit(1)

if __name__ == "__main__":
    main()
