from datetime import datetime
import docker
import hashlib

client = docker.DockerClient(base_url='unix://var/run/docker.sock')

def create_slave():
    """Create Plex slave
    
    Return hostname information compatible with PRT
    """
	
    # Create Docker container for Plex transcoding
    temporary_string = datetime.now().isoformat().encode('utf-8')
	hash_code = str(hashlib.sha256(temporary_string).hexdigest())[0:8]
	container_name = "plex-slave-" + hash_code
    client.containers.run('plex-slave',
	                    name=container_name,
	                    publish_all_ports=True,
	                    detach=True,
	                    auto_remove=True)
    
    print("Created " + container_name + " container")
    
	# Get container IP and port for SSH
	container_ports = client.api.port(container_name, 22)
	output = '192.168.0.185 {0} plex {1}'.format(str(container_ports[0]["HostPort"]), container_name)
	return output

def remove_slave(slave_name):
    """Remove Plex slave
    
    Returns True if removal was successful
    """
    
    active_slave = None
    try:
        active_slave = client.containers.get(slave_name)
    	active_slave.stop()
    except docker.errors.APIError as docker_error:
        print("Error when trying to remove " + slave_name + " container")
        return False
    
    try:
        active_slave.remove()
    except docker.errors.APIError as docker_error:
        print("Container already removed")
        return False
    return True