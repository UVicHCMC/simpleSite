2026-11-09 NOKH1:

The routing for this site and LOI is rather brittle. Before we converted landscapesofinjustice.uvic.ca to be the Discovery Interface, it redirected to landscapesofinjustice.com and loi.uvic.ca was an alias for landscapesofinjustice.uvic.ca. Since Jordan wanted to use landscapesofinjustice.uvic.ca for the discovery interface, we removed the alias and set the documentroot for loi.uvic.ca to be /home1t/loi/www. 

However, landscapesofinjustice.uvic.ca was being used for some URLs in the LOI archive (specifically, for links to PDFs and other media). MH did a mass link update to LOI, however, anyone with old bookmarks would still be trying to link to landscapesofinjustice.uvic.ca. To mitigate this, I've set up an .htaccess redirect on landscapesofinjustice.uvic.ca/archive/ to go to loi.uvic.ca/archive/. I tested it on various pages and files and it seems to work on symlinks as well as real directories. This should hopefully mitigate any issues with old links/bookmarks.

THIS MEANS THAT THE DISCOVERY INTERFACE CANNOT HAVE A /archive/ SUBDIRECTORY. 

The current setup on systems is as follows:

   ServerName loi.uvic.ca
   DocumentRoot "/home1t/loi/www"
   ServerAlias www.loi.uvic.ca
   ServerAlias loi-webserver3.uvic.ca

   ServerName landscapesofinjustice.uvic.ca
   DocumentRoot "/home1t/hcmc/www/project/loi_discovery"
   ServerAlias landscapesofinjustice-webserver3.uvic.ca

And the .htaccess in the root directory is:

RewriteEngine On

RewriteRule ^archive(/.*)?$ https://loi.uvic.ca/archive$1 [R=301,L,NC]

