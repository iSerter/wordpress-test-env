I want to setup multiple WordPress versions with Docker for testing my WordPress plugins.

I think the `main` branch can be a general clean WordPress setups at different ports, without the plugins. 
I will use that one to install the plugins manually from zip files and test. 
I want all minor versions from WordPress 6.1 to 6.9, and also the major version WordPress 7.
I also want WooCommerce installed on each. I want some dummy data seeded. 
We can create helper scripts to setup/configure the WordPress installations and seed dummy data. 
You determine the best and easiest way.


Then, I will create another branch called `with-plugins` and override the docker compose file to add local copies of my plugins for easy debugging if needed, but this can be phase 2. You can create a separate task for phase 2.


Create tasks in the `{repo_root}/tasks` folder.