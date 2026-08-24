# simpleSite

`simpleSite` is an Ant-based static-site build system for small HCMC websites that do not require large datasets. It was initially created for conference websites, although it may be used for other types of sites in future. 

The build reads site-wide configuration from `properties.xml`, combines well-formed XML content with XHTML boilerplate templates, compiles SCSS, and writes the finished site to the `site/` directory. It is written to support both monolingual and multilingual output.

** For internal (HCMC) users, please create a new branch for each new site developed using this repo. External users are welcome to fork the repository and use it for their needs **

## Requirements

The build requires:

- Java 11 or newer;
- Apache Ant;
- [ant-contrib](https://ant-contrib.sourceforge.net/) (the build expects `lib/ant-contrib-1.0b3.jar`, although it may also be installed in Ant's classpath);
- the Saxon HE and VNU Validator JARs referenced in `build.xml`;
- Dart Sass, available as the `sass` command;
- ImageMagick, available as the `identify` command; and
- a Bash-compatible shell.

The deployment target requires `rsync`, SSH access, and the appropriate HCMC credentials. The contents of `lib/`, generated templates, compiled CSS, and the generated site are ignored by Git, so a fresh clone may require the local dependencies to be supplied before it can build.

## Quick start

1. Edit `properties.xml` to describe the site, its languages, navigation, metadata, and asset paths.
2. Add or edit page content in `content/`.
3. Customize the source templates in `boilerplate/` and styles in `scss/` as needed.
4. Run the development build:

   ```sh
   ant fullBuild
   ```

5. Open `site/index.html` in a browser and review the generated pages.

`fullBuild` is the default target, so running `ant` by itself has the same effect. It cleans the existing `site/` directory before rebuilding it.

## Configuration

The build is organized around `properties.xml`. This file contains the language list, site title, contact information, event metadata, navigation, interface labels, image settings, and paths to the site's CSS, JavaScript, favicons, and web manifest.

### Languages

Define every output language in the `<languages>` element. Exactly one language should be marked as the default:

```xml
<languages>
  <lang code="en" label="English" default="true"/>
  <lang code="fr" label="Français"/>
</languages>
```

For a monolingual site, a property's text can appear directly inside its element:

```xml
<siteTitle>Title of Site</siteTitle>
```

For a multilingual site, put each translation in a child element whose name matches a language code:

```xml
<siteTitle>
  <en>Title of Site</en>
  <fr>Titre du site</fr>
</siteTitle>
```

Provide translations for all user-visible metadata, navigation items, and interface labels. The language marked `default="true"` becomes the site's default language; if none is marked, the build uses the first language in the list.

To use a language-selection splash page for a multilingual site, uncomment and configure `<languageSelector>` in `properties.xml`.

### Navigation

Each navigation entry supplies a target file and a label for every language:

```xml
<navigation>
  <item href="about.html">
    <en>About</en>
    <fr>À propos</fr>
  </item>
</navigation>
```

Content filenames and navigation `href` values must agree. The build marks the navigation link for the current page with `class="active"` and `aria-current="page"`.

## Content

Store page content as well-formed XML in `content/`.

For a monolingual site, place XML files directly in that directory:

```text
content/
├── about.xml
└── schedule.xml
```

For a multilingual site, create one subdirectory per language and provide a translated version of every page in the corresponding XML files. Corresponding XML files currently need the same filename in every language:

```text
content/
├── en/
│   ├── about.xml
│   └── schedule.xml
└── fr/
    ├── about.xml
    └── schedule.xml
```

Each file should have a single wrapper element. The wrapper itself is removed and its children are inserted at `<?docContent?>` in the content-page template. The existing `content/about.xml` provides a starting example:

```xml
<div id="root" xmlns="http://www.w3.org/1999/xhtml">
  <h1>About</h1>
  <section id="organization">
    <h2>Organization</h2>
    <p>Page content goes here.</p>
  </section>
</div>
```

When a page contains two or more `<section>` elements, sections that have both an `id` and a heading are included in an automatically generated secondary navigation menu.

## Templates and placeholders

If you wish to modify templates for either the landing/splash page or for content pages you can do some by modifying:

- `boilerplate/landingPageTemplate.xml` for the landing/spash page; and/or
- `boilerplate/contentPageTemplate.xml` for content pages.

Do not edit files in `templates/`. They are generated from the boilerplate files for each configured language and are overwritten during every build.

Templates can retrieve values from `properties.xml` in two ways:

- use a processing instruction such as `<?siteTitle?>` where elements or text should be inserted; and
- use an attribute placeholder such as `href="{?faviconSvg}"` where a property should become part of an attribute value.

The `<?navigation?>` and `<?docContent?>` processing instructions have special build-time behavior. Other placeholder names are resolved against elements in `properties.xml`.

## Assets and styling

- Edit SCSS in `scss/`. The build compiles it into `css/` and copies the result into `site/css/`.
- Store shared images in `images/`. The image-dimension utility records their dimensions so the XSLT can add `width`, `height`, and an aspect-ratio class to generated `<img>` elements.
- Store JavaScript in `js/`, fonts in `fonts/`, and downloadable PDFs in `pdf/`.
- Supply the primary CSS and JavaScript filenames in `<files>` in `properties.xml`.

Running a development build (eg. ant fullBuild) retains stable CSS and JavaScript filenames and the CSS source map. A production build (ant productionReady) gives the primary CSS and JavaScript files content-hashed names, removes the source-map reference, and creates `site/.htaccess` with cache-control rules.

## Ant targets

| Command | Purpose |
| --- | --- |
| `ant fullBuild` | Clean and rebuild the complete development site, including resources, content pages, landing pages, and the sitemap. |
| `ant processSingleContent -Dcontent.file=content/about.xml` | Rebuild one page in a monolingual site. |
| `ant processSingleContent -Dcontent.file=content/fr/about.xml` | Rebuild one page in a multilingual site; the language and output directory are inferred from the path. |
| `ant validateSite` | Run the VNU Validator over HTML files in `site/`. Review the console output for errors. |
| `ant productionReady` | Run a clean production build with cache-busted assets, then validate it. |
| `ant clean` | Remove generated contents from `site/`. |
| `ant rsyncToLiveServer` | Deploy `site/` to the configured HCMC server using `rsync --delete`. |

Additional component targets can be listed with `ant -p`.

## Production setup and deployment

Before producing or deploying a real site:

1. Set the public base URL in the `siteUrl` parameter in `xsl/master_build_sitemap.xsl`; it is used in both `sitemap.xml` and `robots.txt`.
2. Review the project name and the destination in `rsyncToLiveServer` in `build.xml`. The current destination is derived from the lowercase Ant project name.
3. Run `ant productionReady` and resolve any validation errors reported in the console.
4. Inspect the generated `site/` directory.
5. Run `ant rsyncToLiveServer` only when the remote destination is correct. This target uses `--delete`, so files that exist remotely but not in `site/` will be removed.

## Repository layout

```text
boilerplate/   XHTML page templates
content/       XML page content
fonts/         Web fonts copied to the output
images/        Shared site images
js/            JavaScript copied to the output
lib/           Local Java dependencies
pdf/           Downloadable PDF documents
scss/          Sass source files
site/          Generated website
templates/     Generated language-specific templates
utilities/     Build helper scripts and generated image data
xsl/           XSLT build transforms
build.xml      Ant targets and deployment configuration
properties.xml Site-wide configuration and translated interface text
```

## License

See [LICENSE](LICENSE).
