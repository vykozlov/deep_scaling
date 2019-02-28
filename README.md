DEEP scaling
==============

A set of scripts to test scaling of DEEP infrastructure and services.

* submit_orchent_tmpl.sh  :   template for the script to submit a job to DEEP infrastructures

* submit_userapp_multi.sh :   script to deploy NumJobs number of jobs and check if they all were deployed correctly. 

  Has following parameters:
```
   --num_jobs=number       The amount of deployments to submit
   --submit_cmd=command    Script used to submit a single job
   --search_string=string  String to search within curl response
```
* delete_orchent.sh       :   to delete either all deployments at once or one-by-one
* predict_multi.sh        :   to submit multi requests (predict) to a certain endpoint

  Has following parameters:
```
   --num_requests=number   Number of requests to call \n
   --remote_url=url        http://WebAddress:Port, e.g. http://147.213.75.181:10017 \n
   --model=string          Name of the deployed user's Model \n
   --test_dir              Directory with test data (default 'testdata') \n"
```
* check_orchent.sh        :  script to check if deployments respond on the claimed address

  Has following parameters:
```
   --search_string=string  String to search within curl response
```
