#!/bin/bash
#
# Hardbound
# Blogging Like a Hacker
# Copyright (c) 2009 Justin Poliey <jdp34@njit.edu>
#
# Usage:
#	bound [-i indir] [-o outdir]
#

markup="markdown"
indir=$PWD
outdir="$indir"
datefmt="%m/%d/%y"

# build_post infile template
# Put the post body in $postBody
# Compile <template>.tpl to <template>.sh
# Execute <template>.sh, and save as <infile>.html
function build_post()
{
	local infile
	local outfile
	infile=$1
	template=$2
	#nosuffix=$(basename "$infile" .$markup)
	postTitle=$(cat $infile | sed -n '1,/%%/ p' | sed -n 's/[Tt]itle: \(.\+\)/\1/p')
	postDate=$(date --date="`echo "$infile" | sed -n 's/.*\([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\).*/\1/p'`" +"$datefmt")
	if [ -z "$postTitle" ]; then
		echo "Post in \`$infile' needs a title"; exit 1
	fi
	if [ $markup = "markdown" ]; then
		postBody=$(sed -n '/%%/,$ p' $infile | sed -n '2,$ p' | markdown)
	fi
	awk -f template.awk < "$indir/$template.tpl" > "$outdir/$template.sh"
	outfile=$(echo "$postTitle" | sed -e's/[ \t_]/-/g' -e's/[^A-Za-z0-9\-]//g' | tr [A-Z] [a-z])
	. "$outdir/$template.sh" > "$outdir/posts/$outfile.html"
	echo -e "$postTitle\t$postDate\t$outfile.html"
	return
}

function build_posts()
{
	posts=$(get_post_list)
	#echo $posts
	for post in $posts; do
		#echo "Built \`$post'"
		build_post $post post
	done
	return
}

function get_post_list()
{
	echo `find "$indir/_posts" -type f -iregex "$indir/_posts/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-.*\.$markup" | sort`
	return
}

# Cleans up the $outdir directory
function cleanup()
{
	rm -f "$outdir/*.sh"
	return
}

while getopts i:o: o
do
	case "$o" in
		i)   if [ $indir = $outdir ]; then outdir=$OPTARG; fi; indir=$OPTARG;;
		o)   outdir=$OPTARG;;
		[?]) echo "Usage: $0 [-i indir] [-o outfile]"; exit 1;;
	esac
done

if [ ! -d "$indir" ]; then
	echo "Directory \`$indir' does not exist"; exit 1
elif [ ! -d "$outdir" ]; then
	echo "Directory \`$outdir' does not exist"; exit 1
elif [ ! -d "$outdir/_posts" ]; then
	echo "A \`_posts' directory does not exist in \`$outdir'"; exit 1
elif [ ! -f "$indir/index.tpl" ]; then
	echo "No \`index.tpl' file in \`$outdir'"; exit 1
elif [ ! -f "$indir/post.tpl" ]; then
	echo "No \`post.tpl' file in \`$outdir'"; exit 1
fi

echo "Building site from \`$indir' to \`$outdir'"
awk -f template.awk < "$indir/index.tpl" > "$outdir/index.sh"
postIndex=$(build_posts | awk 'BEGIN {FS="\t"} /.*/ { printf("<li><a href=\"posts/%s\">%s</a></li>\n", $3, $1); }')
. "$outdir/index.sh" > "$outdir/index.html"
cleanup
echo "Site built successfully"

