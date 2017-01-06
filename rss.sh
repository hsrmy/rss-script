#!/bin/bash
pre=$(mktemp) temp=$(mktemp)
webhook="https://hooks.slack.com/services/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"

favicon(){
  case $1 in
    nana|nanab )
      favicon="http://mizukinana.jp/favicon.ico"
      channel="#mizukinana";;
    sphere )
      favicon="https://sphere.m-rayn.jp/assets/sphere/favicon-4493e5b29f8b41089dbbba304f78a344.png"
      channel="#sphere";;
    planet )
      favicon="http://lantis-net.com/favicon.ico"
      channel="#sphere";;
    trysail )
      favicon="https://trysail.jp/assets/trysail/favicon-8878bcce2ddb484e9eb3ec1b328066cc.png"
      channel="#trysail";;
    circus )
      favicon="https://emradc.wjg.jp/circus-favicon.ico"
      channel="#general";;
    minako|ayahi|haruka|aki )
      favicon="http://ameblo.jp/favicon.ico"
      channel="#sphere";;
    mocho|sora|nansu )
      favicon="http://ameblo.jp/favicon.ico"
      channel="#trysail";;
  esac
}

list=("nana" "sphere" "trysail" "planet" "circus" "nanab") #公式サイト,ブログ
list+=("minako" "ayahi" "haruka" "aki") #スフィア
list+=("mocho" "sora" "nansu") #TrySail
count=$(echo "${#list[*]}")
for site in ${list[@]} ; do
  file=$(dirname $0)/rss/${site}.xml
  dir=$(dirname $file)
  if [ ! -e $file ]; then
    if [ ! -d $dir ]; then
      mkdir $dir
    fi
    touch $file
    curl -Ss -X GET "https://emradc.wjg.jp/var/rss.xml?site=${site}" > $file
    make+=("${site}.xmlが見つからないため、作成しました。\n")
    if [ ${count} == `echo "${#make[*]}"` ]; then
      data="payload={\"username\": \"RSS Notification\",\"icon_emoji\": \":rss:\",\"text\": \"${make[@]}\"}"
      curl -Ss -X POST --data-urlencode "$data" $webhook > /dev/null
    fi
  fi
  curl -Ss -X GET "https://emradc.wjg.jp/var/rss.xml?site=${site}" > $pre
  title=$(echo "cat /rss/channel/title"|xmllint --shell $pre|grep '<title>'|sed -e "s/<title>\(.*\)<\/title>/\1/")
  diff --old-line-format='' --new-line-format='%L' --unchanged-line-format='' > $temp
  if [ $? -eq 1 ]; then
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
    favicon ${site}
    data="payload={\"channel\": \"$channel\",\"username\": \"$title\",\"icon_url\": \"$favicon\",\"text\": \"${text[@]}\"}"
    curl -Ss -X POST --data-urlencode "$data" $webhook > /dev/null
    IFS=$IFS_ORG
    cp $pre $file
  fi
done
rm $temp $pre
