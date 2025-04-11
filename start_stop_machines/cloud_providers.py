import os
import time
import sys
from abc import ABC, abstractmethod
from dotenv import load_dotenv
load_dotenv()

class CloudProvider(ABC):
    """Base class for cloud providers"""
    
    @abstractmethod
    def start_instance(self, instance_id, **kwargs):
        """Start an instance"""
        pass
    
    @abstractmethod
    def stop_instance(self, instance_id, **kwargs):
        """Stop an instance"""
        pass
    
    @abstractmethod
    def check_instance_status(self, instance_id, **kwargs):
        """Check the status of an instance"""
        pass
    
    @abstractmethod
    def wait_for_running_status(self, instance_id, **kwargs):
        """Wait for the instance to be in running state"""
        pass

class AzureProvider(CloudProvider):
    """Azure cloud provider implementation"""
    
    def __init__(self):
        from azure.identity import ClientSecretCredential
        from azure.mgmt.compute import ComputeManagementClient
        
        # Load Azure credentials
        self.client_id = os.getenv('AZURE_CLIENT_ID')
        self.tenant_id = os.getenv('AZURE_TENANT_ID')
        self.secret = os.getenv('AZURE_CLIENT_SECRET')
        self.subscription_id = os.getenv('AZURE_SUBSCRIPTION_ID')
        self.default_resource_group = os.getenv('AZURE_RESOURCE_GROUP', 'TRI3D_ML')
        
        print(f"[AZURE DEBUG] Initializing Azure provider with resource group: {self.default_resource_group}")
        print(f"[AZURE DEBUG] Client ID present: {bool(self.client_id)}")
        print(f"[AZURE DEBUG] Tenant ID present: {bool(self.tenant_id)}")
        print(f"[AZURE DEBUG] Secret present: {bool(self.secret)}")
        print(f"[AZURE DEBUG] Subscription ID present: {bool(self.subscription_id)}")
        
        # Initialize Azure client
        try:
            self.credential = ClientSecretCredential(self.tenant_id, self.client_id, self.secret)
            self.compute_client = ComputeManagementClient(self.credential, self.subscription_id)
            print(f"[AZURE DEBUG] Successfully initialized Azure compute client")
        except Exception as e:
            print(f"[AZURE DEBUG] Error initializing Azure client: {e}")
            raise
    
    def check_instance_status(self, instance_id, resource_group=None, **kwargs):
        """Check the status of an Azure VM"""
        resource_group = resource_group or self.default_resource_group
        print(f"[AZURE DEBUG] Checking status of VM {instance_id} in resource group {resource_group}")
        try:
            vm_instance_view = self.compute_client.virtual_machines.get(
                resource_group, 
                instance_id, 
                expand='instanceView'
            )
            statuses = vm_instance_view.instance_view.statuses
            for status in statuses:
                if status.code.startswith('PowerState/'):
                    power_state = status.code.split('/')[-1]
                    print(f"[AZURE DEBUG] VM {instance_id} power state: {power_state}")
                    return power_state
            print(f"[AZURE DEBUG] No power state found for VM {instance_id}")
            return None
        except Exception as e:
            print(f"[AZURE DEBUG] Error checking VM status: {e}")
            raise
    
    def start_instance(self, instance_id, resource_group=None, **kwargs):
        """Start an Azure VM"""
        resource_group = resource_group or self.default_resource_group
        print(f"[AZURE DEBUG] Starting instance {instance_id} in resource group {resource_group}")
        
        try:
            vm_status = self.check_instance_status(instance_id, resource_group)
            print(f"[AZURE DEBUG] Current VM status before starting: {vm_status}")
            
            if vm_status in ['deallocated', 'stopped', 'failed']:
                print(f"[AZURE DEBUG] Starting Azure VM: {instance_id}")
                async_vm_start = self.compute_client.virtual_machines.begin_start(resource_group, instance_id)
                print(f"[AZURE DEBUG] Begin_start operation initiated, waiting for completion...")
                async_vm_start.wait()
                print(f"[AZURE DEBUG] Azure VM {instance_id} started successfully")
                return True
            elif vm_status == 'running':
                print(f"[AZURE DEBUG] Azure VM {instance_id} is already running.")
                return True
            elif vm_status == 'stopping':
                error_message = f"Azure VM {instance_id} is currently stopping. Please wait for it to fully stop before starting."
                print(f"[AZURE DEBUG] {error_message}")
                raise ValueError(error_message)
            else:
                error_message = f"Azure VM {instance_id} is in a state that cannot be started: {vm_status}"
                print(f"[AZURE DEBUG] {error_message}")
                raise ValueError(error_message)
        except Exception as e:
            print(f"[AZURE DEBUG] Error in start_instance: {e}")
            raise
    
    def stop_instance(self, instance_id, resource_group=None, **kwargs):
        """Stop and deallocate an Azure VM"""
        resource_group = resource_group or self.default_resource_group
        vm_status = self.check_instance_status(instance_id, resource_group)
        
        if vm_status == 'running':
            print(f"Deallocating Azure VM: {instance_id}")
            async_vm_stop = self.compute_client.virtual_machines.begin_deallocate(resource_group, instance_id)
            async_vm_stop.wait()
            print(f"Azure VM {instance_id} deallocated.")
            return True
        else:
            print(f"Azure VM {instance_id} is not in running state. Current state: {vm_status}")
            return False
    
    def wait_for_running_status(self, instance_id, resource_group=None, timeout=300, **kwargs):
        """Wait for the Azure VM to be in running state"""
        resource_group = resource_group or self.default_resource_group
        print(f"[AZURE DEBUG] Waiting for VM {instance_id} to reach running state (timeout: {timeout}s)")
        
        start_time = time.time()
        while (time.time() - start_time) < timeout:
            try:
                status = self.check_instance_status(instance_id, resource_group)
                print(f"[AZURE DEBUG] Current status while waiting: {status}, elapsed time: {time.time() - start_time:.1f}s")
                
                if status == 'running':
                    print(f"[AZURE DEBUG] VM {instance_id} is now running")
                    # Give the VM a moment to initialize services
                    wait_time = 15
                    print(f"[AZURE DEBUG] Waiting {wait_time}s for services to initialize...")
                    time.sleep(wait_time)
                    print(f"[AZURE DEBUG] VM {instance_id} should be ready for connections now")
                    return True
                print(f"[AZURE DEBUG] Waiting for Azure VM {instance_id} to start (Current status: {status})...")
                time.sleep(10)
            except Exception as e:
                print(f"[AZURE DEBUG] Error checking status while waiting: {e}")
                time.sleep(10)
        
        print(f"[AZURE DEBUG] Timeout waiting for Azure VM {instance_id} to start")
        return False

class AWSProvider(CloudProvider):
    """AWS cloud provider implementation"""
    
    def __init__(self):
        import boto3
        
        # Load AWS credentials from environment variables
        # AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY are automatically loaded by boto3
        self.region = os.getenv('AWS_DEFAULT_REGION', 'us-east-1')
        
        # Initialize AWS client
        self.ec2 = boto3.resource('ec2', region_name=self.region)
        self.ec2_client = boto3.client('ec2', region_name=self.region)
    
    def check_instance_status(self, instance_id, region=None, **kwargs):
        """Check the status of an AWS EC2 instance"""
        if region and region != self.region:
            # Create a client for the specified region
            import boto3
            ec2_client = boto3.client('ec2', region_name=region)
            response = ec2_client.describe_instances(InstanceIds=[instance_id])
        else:
            response = self.ec2_client.describe_instances(InstanceIds=[instance_id])
        
        # Extract instance state
        try:
            state = response['Reservations'][0]['Instances'][0]['State']['Name']
            return state
        except (IndexError, KeyError):
            print(f"Error retrieving status for AWS instance {instance_id}")
            return None
    
    def start_instance(self, instance_id, region=None, **kwargs):
        """Start an AWS EC2 instance"""
        if region and region != self.region:
            # Create a client for the specified region
            import boto3
            ec2_client = boto3.client('ec2', region_name=region)
            instance_status = self.check_instance_status(instance_id, region)
        else:
            ec2_client = self.ec2_client
            instance_status = self.check_instance_status(instance_id)
        
        if instance_status == 'stopped':
            print(f"Starting AWS instance: {instance_id}")
            response = ec2_client.start_instances(InstanceIds=[instance_id])
            print(f"AWS instance {instance_id} starting...")
            return True
        elif instance_status == 'running':
            print(f"AWS instance {instance_id} is already running.")
            return True
        elif instance_status == 'stopping':
            error_message = f"AWS instance {instance_id} is currently stopping. Please wait for it to fully stop before starting."
            print(error_message)
            raise ValueError(error_message)
        else:
            error_message = f"AWS instance {instance_id} is in a state that cannot be started: {instance_status}"
            print(error_message)
            raise ValueError(error_message)
    
    def stop_instance(self, instance_id, region=None, **kwargs):
        """Stop an AWS EC2 instance"""
        if region and region != self.region:
            # Create a client for the specified region
            import boto3
            ec2_client = boto3.client('ec2', region_name=region)
            instance_status = self.check_instance_status(instance_id, region)
        else:
            ec2_client = self.ec2_client
            instance_status = self.check_instance_status(instance_id)
        
        if instance_status == 'running':
            print(f"Stopping AWS instance: {instance_id}")
            response = ec2_client.stop_instances(InstanceIds=[instance_id])
            print(f"AWS instance {instance_id} stopping...")
            return True
        else:
            print(f"AWS instance {instance_id} is not in running state. Current state: {instance_status}")
            return False
    
    def wait_for_running_status(self, instance_id, region=None, timeout=300, **kwargs):
        """Wait for the AWS EC2 instance to be in running state"""
        if region and region != self.region:
            # Create a client for the specified region
            import boto3
            ec2_client = boto3.client('ec2', region_name=region)
            waiter = ec2_client.get_waiter('instance_running')
        else:
            waiter = self.ec2_client.get_waiter('instance_running')
        
        try:
            print(f"Waiting for AWS instance {instance_id} to be in running state...")
            waiter.wait(
                InstanceIds=[instance_id],
                WaiterConfig={
                    'Delay': 10,
                    'MaxAttempts': timeout//10  # Convert timeout to number of attempts
                }
            )
            print(f"AWS instance {instance_id} is now running")
            # Give the instance some time to initialize services
            time.sleep(15)
            return True
        except Exception as e:
            print(f"Error waiting for AWS instance {instance_id} to start: {e}")
            return False
            
    def wait_for_stopped_status(self, instance_id, region=None, timeout=300, **kwargs):
        """Wait for the AWS EC2 instance to be in stopped state"""
        if region and region != self.region:
            # Create a client for the specified region
            import boto3
            ec2_client = boto3.client('ec2', region_name=region)
            waiter = ec2_client.get_waiter('instance_stopped')
        else:
            waiter = self.ec2_client.get_waiter('instance_stopped')
        
        try:
            print(f"Waiting for AWS instance {instance_id} to be fully stopped...")
            waiter.wait(
                InstanceIds=[instance_id],
                WaiterConfig={
                    'Delay': 10,
                    'MaxAttempts': timeout//10  # Convert timeout to number of attempts
                }
            )
            print(f"AWS instance {instance_id} is now fully stopped")
            return True
        except Exception as e:
            print(f"Error waiting for AWS instance {instance_id} to stop: {e}")
            return False

def get_cloud_provider(provider_name):
    """Factory function to get the appropriate cloud provider"""
    providers = {
        'azure': AzureProvider,
        'aws': AWSProvider
    }
    
    if provider_name.lower() not in providers:
        raise ValueError(f"Unsupported cloud provider: {provider_name}")
    
    return providers[provider_name.lower()]() 