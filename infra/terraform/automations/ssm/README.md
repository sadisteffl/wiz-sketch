https://www.wiz.io/blog/nvidia-ai-vulnerability-cve-2025-23266-nvidiascape

1. Write the C code 
The goal of this payload is to simply run the `id` command and write its output to a file named /owned on the host's root directory, proving you have escaped the container.
2. Compile the code into shared object 
n the same directory as poc.c, run the following command to compile it into the required poc.so file.

`gcc -shared -fPIC -o poc.so poc.c`


3. Build the malicous container image 
Use the docker build command to create your malicious container image. You can name it 

nct-exploit as shown in the documentation. 

4. Execute the Exploit and Validate
With the malicious image built, the final steps are to run it and verify the container escape.

Step 1: Run the malicious container
Execute the following command on your vulnerable host. The 

--runtime=nvidia flag is essential as it invokes the vulnerable NVIDIA Container Toolkit hooks.

Step 2: Verify the host compromise

If the exploit was successful, the poc.so library will have been loaded by the privileged host process, and it will have created the /owned file on the host machine's filesystem.

From the host machine's terminal, check the contents of the file: 

cat /owned
You should see the output confirming you have root access on the host, successfully escaping the container: 

By following these steps, you will have perfectly replicated the NVIDIAScape exploit, demonstrating a deep understanding of a critical, real-world vulnerability in an AI-centric infrastructure, which is a key goal of the Wiz technical exercise. 