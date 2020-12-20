--  luacheck: max line length 10000
local arg = ...
if arg == "chart.html" then return "<!DOCTYPE html><html><head> <meta http-equiv=\"content-type\" content=\"text/html; charset=UTF-8\"> <title>Altitude logger - $LOGFILE</title> <meta http-equiv=\"content-type\" content=\"text/html; charset=UTF-8\"> <meta name=\"robots\" content=\"noindex, nofollow\"> <meta name=\"googlebot\" content=\"noindex, nofollow\"> <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\"> <script type=\"text/javascript\" src=\"http://code.jquery.com/jquery-1.9.1.js\" ></script><style type=text/css>* {margin: 0;padding: 0;}html,body {height: 100%;font-family: sans-serif;text-align: center;background: #444d44;}#content {position: absolute;top: 0;right: 0;bottom: 0;left: 0;width: 800px;height: 480px;margin: auto;}input {-webkit-appearance: none;border-radius: 0;}fieldset {border: 0;box-shadow: 0 0 15px 1px rgba(0, 0, 0, .4);box-sizing: border-box;padding: 20px 30px;background: #fff;min-height: 320px;margin: -1px;}input {border: 1px solid #ccc;margin-bottom: 10px;width: 100%;box-sizing: border-box;color: #222;font: 16px monospace;padding: 15px;}select {font: 16px monospace;background-color: transparent;padding: 15px;}.button {color: #fff;border: 1;border-radius: 3px;cursor: pointer;font: 16px sans-serif;text-decoration: none;padding: 10px 5px;background: #31b457;width: 24%;}.button:focus,.button:hover {box-shadow: 0 0 0 2px #fff, 0 0 0 3px #31b457;} .button:disabled { border: 1px solid #999999; background-color: #cccccc; color: #666666; pointer-events:none; cursor: not-allowed; }h3 {font-size: 19px;color: #666;margin-bottom: 20px;}h4 {color: #666; text-align: left;}</style><script src=\"https://code.highcharts.com/stock/highstock.js\"></script><script src=\"https://code.highcharts.com/stock/highcharts-more.js\"></script><script src=\"https://code.highcharts.com/modules/exporting.js\"></script><script src=\"http://cdnjs.cloudflare.com/ajax/libs/lodash.js/2.4.1/lodash.min.js\"></script> \
<script type=\"text/javascript\">$(function(){console.log(\"$function\"),chart=new Highcharts.Chart({chart:{renderTo:\"container\",marginBottom:100,events:{load:altchartOnLoad}},title:{text:\"\"},legend:{enabled:\"true\",layout:\"horizontal\",align:\"center\",verticalAlign:\"bottom\",borderWidth:0},xAxis:{type:\"datetime\",offset:30,dateTimeLabelFormats:{second:\"%M:%S\"}},yAxis:[{title:{text:\"Altitude\"},labels:{format:\"{value} m\"}}]})});var getData=function(t,e,o){$.ajax({url:t,tryCount:0,retryLimit:3,success:function(t){e(t,o)},error:function(t,e,o){return console.log(\"error\",t,e,o),\"timeout\"==e||500==t.status?(this.tryCount++,this.tryCount<=this.retryLimit?void $.ajax(this):void 0):void 0}})},processJson=function(t,e){for(var o=[],a=0;a<t.length;a++)o[a]=[1e3*a,Math.round(parseFloat(t[a])*Math.pow(10,e))/Math.pow(10,e)];return o},twoDigits=function(t){return t<10?\"0\"+t:t},captionsMax=function(t){var e=[],o=t[0][0],a=t[0][1];t.map(function(t){t[1]>a&&(o=t[0],a=t[1])}),console.log(\"Local max: idx: \"+o+\": \"+a+\" m\");var i=new Date(o);return e.push({x:o,title:a+\" m<br><small>(\"+twoDigits(i.getMinutes())+\":\"+twoDigits(i.getSeconds())+\")</small>\",color:\"#900000\"}),e},altchartOnLoad=function(){getData(\"/?section=logfiles&id=$LOGFILE&action=JSON\",function(t){console.log(\"getData callback\");var e=processJson(t,1);chart.addSeries({name:\"Altitude\",id:\"altitude\",data:e,type:\"spline\",color:\"#8FD8F7\",pointStart:Date.UTC(2010,0,1),pointInterval:1e3,tooltip:{valueSuffix:\" m\"}});var o=captionsMax(e);chart.addSeries({type:\"flags\",onSeries:\"altitude\",shape:\"flag\",showInLegend:!1,useHTML:!0,shadow:!0,linkedTo:\"altitude\",y:10,fillColor:\"rgba(255,255,255,0.4)\",data:o})})};</script></head>\
<body><div id=content><fieldset> <h3>Altitude logger - Chart</h3><div id=\"container\" style=\"min-width: 310px; height: 400px; margin: 40 auto\"></div><canvas id=\"canvas\" width=\"1000px\" height=\"600px\" style=\"display:none;\"></canvas><br><form action=\"/\" method=\"post\"> <input type=\"submit\" value=\"Back\" class='button' name=\"submit\" /></form></fieldset></div></body></html>"  end

if arg == "favicon.ico" then return "\000\000\000\000\000\000\000\000h\000\000\000\000\000(\000\000\000\000\000\000 \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000�����������ƽ�����\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000���������OOO\000\000\000\000\000\000hhh���������\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000������\000\000\000\000\000\000\000\000\000uuu^^^\000\000\000\000\000\000@@@������\000\000\000\000\000\000\000\000\000������\000\000\000\000\000\000QQQ������������\000\000\000\000\000\000������\000\000\000��ݴ��\000\000\000\000\000\000\000\000\000������������\000\000\000\000\000\000\000\000\000LLL���\000\000\000������\000\000\000\000\000\000\000\000\000\000\000\000\r\r\r\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000�����ʹ��\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000```������\000\000\000\000\000\000\000\000\000\000\000\000���������\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000���333iii���\000\000\000\000\000\000\000\000\000\000\000\000YYY������\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000���333iii���vvv\000\000\000\000\000\000\000\000\000ZZZ������\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000```��ͼ��uuu������\000\000\000\000\000\000������������\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000���zzz\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000��������ݴ��\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000���www\000\000\000\000\000\000\000\000\000\000\000\000LLL���\000\000\000\000\000\000������\000\000\000\000\000\000\000\000\000\000\000\000���vvv\000\000\000\000\000\000\000\000\000������\000\000\000\000\000\000\000\000\000������\000\000\000\000\000\000\000\000\000���MMM\000\000\000\000\000\000@@@������\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000���������OOO???\000\000\000hhh���������\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000�����������ƽ�����\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000�\000\000�\000\000�\000\000�\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000�\000\000�\000\000�\000\000�\000\000"  end

if arg == "index.html" then return "<!DOCTYPE html><html><head><meta name='viewport' content='width=device-width, initial-scale=1.0'><title>Altitude logger</title>\
<style type=text/css>* {margin: 0;padding: 0;}html,body {height: 100%;font-family: sans-serif;text-align: center;background: #444d44;}#content {position: absolute;top: 0;right: 0;bottom: 0;left: 0;width: 800px;height: 480px;margin: auto;}input {-webkit-appearance: none;border-radius: 0;}fieldset {border: 0;box-shadow: 0 0 15px 1px rgba(0, 0, 0, .4);box-sizing: border-box;padding: 20px 30px;background: #fff;min-height: 320px;margin: -1px;}input {border: 1px solid #ccc;margin-bottom: 10px;width: 100%;box-sizing: border-box;color: #222;font: 16px monospace;padding: 15px;}select {font: 16px monospace;background-color: transparent;padding: 15px;}.button {color: #fff;border: 1;border-radius: 3px;cursor: pointer;font: 16px sans-serif;text-decoration: none;padding: 10px 5px;background: #31b457;width: 24%;}.button:focus,.button:hover {box-shadow: 0 0 0 2px #fff, 0 0 0 3px #31b457;} .button:disabled { border: 1px solid #999999; background-color: #cccccc; color: #666666; pointer-events:none; cursor: not-allowed; }h3 {font-size: 19px;color: #666;margin-bottom: 20px;}h4 {color: #666; text-align: left;} .tg {undefined;table-layout: fixed; width: 100%} .tg td{padding:3px 10px 0px 10px;border-style:none;overflow:hidden;word-break:normal;} .tg .tg-ccaptions {width:30%} .tg .tg-cdettime {width:7%} .tg .tg-cdetrecs {width:15%} .tg .tg-buttons {text-align:left;vertical-align:bottom} .tg .tg-caption {text-align:right;vertical-align:center; font-weight: bold;} .tg .tg-dettime {text-align:right;vertical-align:center; font-size: smaller} .tg .tg-detrecs {text-align:right;vertical-align:center; font-size: smaller}</style>\
<script> function formHandler(event) { if (event.submitter.value == \"Delete\") { return confirm(\"Do you want to delete '\" + event.target.id.value + \"'?\"); } else if  (event.submitter.value == \"Chart\") { this.location.replace(\"/chart.html?section=logfiles&id=\" + event.target.id.value + \"&action=Chart\"); return false; } else { return true; } } </script></head>\
<body><div id=content><fieldset> <h3>Altitude logger</h3> <h4>Log files</h4> <table class=\"tg\"> <colgroup><col class=\"tg-ccaptions\"><col class=\"tg-cdettime\"><col class=\"tg-cdetrecs\"><col></colgroup>\
<tr> <td class=\"tg-caption\">$LOGFILE</td> <td class=\"tg-dettime\">$DETTIME</td> <td class=\"tg-detrecs\">$DETRECS</td> <td class=\"tg-buttons\"> <form onsubmit=\"return formHandler(event);\" src=\"/\" method=\"post\"> <input type=\"hidden\" name=\"section\" value=\"logfiles\" readonly=\"readonly\"/> <input type=\"hidden\" name=\"id\" value=\"$LOGFILE\" readonly=\"readonly\"/> <input type=\"submit\" class='button' name='action' value=\"Chart\"/> <input type=\"submit\" class='button' name='action' value=\"JSON\" /> <input type=\"submit\" class='button' name='action' value=\"CSV\"/> <input type=\"submit\" class='button' name='action' value=\"Delete\" /> </form> </td> </tr>\
</table></fieldset></div></body></html>"  end

