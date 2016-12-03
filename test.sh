#!/bin/bash
pre=$(mktemp) temp=$(mktemp)
webhook="https://hooks.slack.com/services/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"

favicon(){
  case $1 in
    nana )
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

list=("nana" "sphere" "trysail" "planet" "circus") #公式サイト
list+=("minako" "ayahi" "haruka" "aki") #スフィア
list+=("mocho" "sora" "nansu") #TrySail
for site in ${list[@]} ; do
  echo $site
  file=$(dirname $0)/rss/${site}.xml
  if [ ! -e $file ]; then
    if [ ! -d $dir ]; then
      mkdir $dir
    fi
    touch $file
    curl -Ss -X GET "https://emradc.wjg.jp/dhcp/rss.xml?site=${site}" > $file
    text="${site}.xmlが見つからないため、作成しました。"
    data="payload={\"username\": \"RSS Notification\",\"text\": \"$text\"}"
    curl -Ss -X POST --data-urlencode "$data" $webhook > /dev/null
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
    favicon ${site}
    data="payload={\"channel\": \"$channel\",\"username\": \"$title\",\"icon_url\": \"$favicon\",\"text\": \"${text[@]}\"}"
    curl -Ss -X POST --data-urlencode "$data" $webhook > /dev/null
    IFS=$IFS_ORG
    cp $pre $file
  fi
done
rm $temp $pre
