#!/bin/bash
pre=$(mktemp) temp=$(mktemp)
webhook="https://hooks.slack.com/services/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"
for site in nana sphere trysail planet circus; do
  file="/Users/hsrmy/rss/${site}.xml"
  if [ ! -e $file ]; then
    touch $file
  fi
  curl -Ss -X GET "https://emradc.wjg.jp/var/rss.xml?site=${site}" > $pre
  title=$(echo "cat /rss/channel/title"|xmllint --shell $pre|grep '<title>'|sed -e "s/<title>\(.*\)<\/title>/\1/")
  diff $file $pre|sed -e "s/^> //"|grep '<item>' > $temp
  if [ ${PIPESTATUS[0]} -eq 1 ]; then
    count=`wc -l $temp|awk '{print $1}'`
    text=(" ${title} の更新です!\n\n")
    IFS_ORG=$IFS
    IFS=$'\n'
    line=(`cat ${temp}`)
    for i in ${line[@]}; do
      article_title=`echo $i|sed -e "s/.*<title>\(.*\)<\/title>.*/\1/"`
      article_url=`echo $i|sed -e "s/.*<link>\(.*\)<\/link>.*/\1/"`
      article_description=`echo $i|sed -e "s/.*<description>\(.*\)<\/description>.*/\1/"`
      if [ "$article_title" = "$article_description" ]; then
        text_pre="<$article_url|$article_title>"
      else
        text_pre="<$article_url|$article_title>\n$article_description"
      fi
      if [ "$text_pre" != "<|>" ]; then
        text+=("$text_pre\n")
      fi
    done
    data="payload={\"channel\": \"#random\",\"username\": \"$title\",\"icon_url\": \"$favicon\",\"text\": \"${text[@]}\"}"
    curl -Ss -X POST --data-urlencode "$data" $webhook > /dev/null
    IFS=$IFS_ORG
    cp $temp $file
  fi
done
rm $temp $pre
