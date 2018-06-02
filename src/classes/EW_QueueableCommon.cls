/**
*	各種System.Queueable共通クラス
*/
global with sharing class EW_QueueableCommon {
	/**
	*	非同期返信処理（Reply Message）
	*/
    global class QueueableReplyMessage implements System.Queueable, Database.AllowsCallouts{
		// LINE設定
		private String LINE_REPLY_MSG_URI = 'https://api.line.me/v2/bot/message/reply';
		private String LINE_AT_CH_ACCESS_TOKEN = 'xxxxx';			// 自身の環境のアクセストークンを貼り付け
		// メッセージデータ
        String jsonBody;

        global QueueableReplyMessage(String jsonBody) {
            this.jsonBody= jsonBody;
        }

        global void execute(System.QueueableContext ctx) {
            // 送信データを作成して送信
            HttpRequest req = new HttpRequest();
			req.setHeader('Authorization', 'Bearer '+ LINE_AT_CH_ACCESS_TOKEN);
			req.setHeader('Content-Type', 'application/json');
			req.setEndpoint(LINE_REPLY_MSG_URI);
            req.setMethod('POST');
            req.setBody(jsonBody);
            Http http = new Http();
            HTTPResponse res = http.send(req);
        }
    }
}