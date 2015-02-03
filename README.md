# 302.sh
Easily add 302 redirects to an .htaccess with duplicate checker

## See the script for details

It is thoroughly commented throughout.

You will need to tell the script which app you are using to sync your local .htaccess with the server _and_ you will need to tell it what the domain name is for the URLs that you want to create.

These can both be set by editing these lines in the `302.sh` file:

	# This could also be Dropbox or something else
	SYNC_APP="BitTorrent Sync"

	# this is the domain to use with the short URLs
	YOUR_DOMAIN='luo.ma'

## Usage: Two Args

Ideally you will give the `302.sh` two arguments:

1.	the "slug" that you want to use with your domain name

2.	the URL that you want the slug to redirect to.

Example:

	302.sh Foo http://some.tld/path/to/whatever/you/want

Ok, but that's a theoretical. Here’s an actual example: say I want “CleanDesktop” to redirect to “http://luo.ma/geek/keep-desktop-clean-by-name”. Here’s what I would do:

	302.sh CleanDesktop http://luo.ma/geek/keep-desktop-clean-by-name

Note that it doesn’t matter which comes first, the URL or the slug, so I could have also done this:

	302.sh http://luo.ma/geek/keep-desktop-clean-by-name CleanDesktop

and it would have given me the same result.

### What `302.sh` does

First, the script checks the `.htaccess` file to make sure that you aren’t trying to re-use a slug, because that would be bad.

Secondly, it will add the appropriate redirection line to .htaccess. In this case it would be

	redirect 302 /CleanDesktop			http://luo.ma/geek/keep-desktop-clean-by-name

If the slug that you have chosen is _not_ all lowercase, then `302.sh` will _also_ add a lowercase version to the .htaccess. So, using this example again, it would also add:

	redirect 302 /cleandesktop			http://luo.ma/geek/keep-desktop-clean-by-name

I prefer to use CamelCase when I make short URLs, but if I tell someone the URL, I don’t want them to have to worry about capitalization.

`302.sh` checks .htaccess for both the original and lowercase-d versions of the slug, and if either exist, it will refuse to add the new slug, and tell you why.

## Usage: One Arg

You do not _have_ to give `302.sh` two arguments. For example, you could just tell it the URL that you have, and it will prompt you for the slug. For example, if I had said

	302.sh http://luo.ma/geek/keep-desktop-clean-by-name

then it would ask:

	What slug do you want to use for 'http://luo.ma/geek/keep-desktop-clean-by-name'?

Or you could give it the slug and it will ask for the URL.

(It does this by checking the first 4 letters of the input. If it is “http” then it assumes that is the URL. If it starts with something else, it assumes that is the slug.)

## Usage: Other

If you give `302.sh` something _other_ than 1 or 2 arguments (for example: 0 or 5 or 237), it will not try to guess what you mean, and will prompt you for both the URL and the slug.

