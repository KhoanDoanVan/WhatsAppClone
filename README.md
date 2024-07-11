# WhatsAppClone

Channel
<div>-- channelId: Random String</div>
<div>-- admins: [uid, uid, uid]</div>
<div>-- members: [uid, uid, uid, uid]</div>
<div>-- creationDate: TimeInterval</div>
<div>-- membersCount: Int</div>
<br/>
Channel-Messages
<div>-- channelId</div>
<div>---- messageId</div>
<div>------ message: { text, timestamp, sender }</div>
<br/>
User-Direct-Messages
<div>-- userId</div>
<div>---- channelId1: true</div>
<div>---- channelId2: true</div>
<br/>
<div>Direct Channels: unique, 1:1, communication with 2 members</div>
<div>Group Channels: non-unique, 3 to 12 members</div>
<br/>
<div>- Denormalization: Optimize for Read operations, sacrificing Write</div>
<div>- Storage is cheap in firebase</div>
