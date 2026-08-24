# simpleSite
This is a repository for a simple ant build process for HCMC websites that do not have large datasets. The build process was initially created for conference websites, though some branches may eventually be used for other types of sites. 

It requires java libraries that are in the /lib/ folder. It also requires ant-contrib.


## Properties
The build process is designed around the **properties.xml** file. This file contains all of the basic site information, such as the languages in which the site appears, the site title, contact info, basic event information (for conferences), and pathing/filenames for the site files (eg. CSS, JS). 

The build process is configured to work with either monolingual or muilti-lingual builds. It will use the list of languages set out in **properties.xml** to decide whether the site is monolingual, bi-lingual, tri-lingual etc. It will default to whichever language has been assigned `@default="true"` in cases of ambiguity. For monolingual builds, information can be stored directly in the appropriate element (eg. `<siteTitle>Title of Site</siteTitle>`). For multi-lingual builds, information must be nested inside language-specific child elements (defined in the `<languages>` element at the top of the file). For example: 

```
<siteTitle>
  <en>Title of Site</en>
  <fr>Titre du Site</fr>
</siteTitle>
```

### Content

Content for the site must be stored in well-formed XML in the **content** directory. For monolingual sites, each XML file can be stored directly in the **content** directory. For multi-lingual sites, content must be stored in child directories, with a separate file for each language. At this stage, the file names have to be the same in both languages (eg. content/en/gettinghere.xml and content/fr/gettinghere.xml, not content/fr/venir.xml).

