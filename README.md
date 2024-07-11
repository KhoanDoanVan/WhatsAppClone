# WhatsAppClone

Channel
<div>-- channelId: Random String</div>
<div>-- admins: [uid, uid, uid]</div>
<div>-- members: [uid, uid, uid, uid]</div>
<div>-- creationDate: TimeInterval</div>
<div>-- membersCount: Int</div>

Channel-Messages
-- channelId
---- messageId
------ message: { text, timestamp, sender }

User-Direct-Messages
-- userId
---- channelId1: true
---- channelId2: true

Direct Channels: unique, 1:1, communication with 2 members
Group Channels: non-unique, 3 to 12 members

- Denormalization: Optimize for Read operations, sacrificing Write
- Storage is cheap in firebase
