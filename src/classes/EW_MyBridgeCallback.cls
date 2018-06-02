/**
*	myBridgeに登録した名刺情報をLINE@経由で受け取るクラス
*/
@RestResource(urlMapping='/myBridgeCallback')
global with sharing class EW_MyBridgeCallback {
	/**
	*	変数設定
	*/
	// 組織設定
	private static String SERVER_URL = URL.getSalesforceBaseUrl().toExternalForm();
	//「私のドメイン」関連で、上の書き方で上手くいかない時は自分の組織に合わせて書き換えてください
	// private static String SERVER_URL = 'https://xxxx.my.salesforce.com';

	/**
	*	POSTされたデータの処理
	*	@return Boolean
	*/
    @HttpPost
    global static Boolean doPost() {
		/**
		*	POSTされたデータを展開
		*/
		RestRequest req = RestContext.request;
		Map<String, Object> callbackParams = (Map<String, Object>)JSON.deserializeUntyped(req.requestBody.ToString());
		List<Object> resultParams = (List<Object>)callbackParams.get('events');
		String replyToken;

		// eventsのデータを展開
		for (Object obj : resultParams) {
            Map<String, Object> params = (Map<String, Object>)obj;
            // ReplyTokenを取得
            replyToken = (String)params.get('replyToken');
            String eventType = (String)params.get('type');
            Map<String, Object> sourceParams = (Map<String, Object>)params.get('source');

			// eventTypeが「message」の場合のみ処理
            if( eventType == 'message' ){
                // メッセージを取得
                Map<String, Object> msgParams = (Map<String, Object>)params.get('message');
                String msgTypeStr = (String)msgParams.get('type');

                // POSTされた名刺情報を取得
                if( msgTypeStr == 'text' ){
					// リードを作成
					Lead newLead = new Lead();

                    // メッセージ取得
                    String msgStr = (String)msgParams.get('text');
					List<String> msgList = msgStr.split('\n');
					if( msgList.size() > 0 ){
						for( String msg : msgList ){
							// 名前
							if( msg.contains('名前:') ){
								String tmpName = msg.removeStart('名前:');
								List<String> tmpNameStrs = tmpName.split(' ');
								newLead.LastName = tmpNameStrs[0];
								if( tmpNameStrs.size() > 1 ){
									newLead.FirstName = tmpNameStrs[1];
								}
							}
							// 部署（標準の入れ先がないので説明へ）
							if( msg.contains('部署:') ){
								newLead.Description = msg.removeStart('部署:');
							}
							// 役職
							if( msg.contains('役職:') ){
								newLead.Title = msg.removeStart('役職:');
							}
							// メールアドレス
							if( msg.contains('メールアドレス:') ){
								newLead.Email = msg.removeStart('メールアドレス:');
							}
							// 携帯電話
							if( msg.contains('携帯電話:') ){
								newLead.MobilePhone = msg.removeStart('携帯電話:');
							}
							// 会社名
							if( msg.contains('勤務先:') ){
								newLead.Company = msg.removeStart('勤務先:');
							}
							// 会社電話
							if( msg.contains('会社電話:') ){
								newLead.Phone = msg.removeStart('会社電話:');
							}
							// ファックス番号
							if( msg.contains('ファックス番号:') ){
								newLead.Fax = msg.removeStart('ファックス番号:');
							}
							// 住所
							if( msg.contains('住所:') ){
								newLead.Street = msg.removeStart('住所:');
							}
						}
						// リードを登録
						insert newLead;

						// 返信メッセージを作成
						Map<String, Object> msgMaps = new Map<String, Object>();
						List<Object> msgObjs = new List<Object>();
						Map<String, Object> msgItemMaps = new Map<String, Object>();
						msgItemMaps.put('type', 'text');
						String retMsgStr = '名刺情報をSalesforceに取り込みました\n'+ SERVER_URL +'/'+ newLead.Id;
						
						msgItemMaps.put('text', retMsgStr);
						msgObjs.add(msgItemMaps);
						msgMaps.put('messages', msgObjs);
						msgMaps.put('replyToken', replyToken);
						String jsonBody = Json.serialize(msgMaps);

						// 登録完了メッセージを返信
						System.enqueueJob(new EW_QueueableCommon.QueueableReplyMessage(jsonBody));
					}
                }
            }
		}
		return true;
	}
}