public with sharing class EmailSender {
	
	private String subject;
	private String body;
	private List<String> recipients;
	
	public EmailSender() {
		recipients = new List<String>();
	}
	
	public EmailSender subject(String subjectText) {
		this.subject = subjectText;
		return this;
	}
	
	public EmailSender body(String bodyText) {
		this.body = bodyText;
		return this;
	}
	
	public EmailSender addRecipient(String recipient) {
		recipients.add(recipient);
		return this;
	}
	
	public EmailSender includeCurrentUser() {
		String currentUserId = UserInfo.getUserId();
    	User currentUser = [ SELECT Id, Email FROM User WHERE Id = :currentUserId ];
    	recipients.add(currentUser.Email);
		return this;
	}
	
	private Messaging.SingleEmailMessage build() {
		if (subject == null || body == null || recipients.size() < 1) {
			throw new EmailFieldNotSetException();
		}
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		mail.setToAddresses(recipients);
		mail.setSubject(subject);
    	mail.setPlainTextBody(body);
    	return mail;
	}
	
	public void send() {
		Messaging.SingleEmailMessage mail = build();
		if(Test.isRunningTest()) {
			return;
		}
    	Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
	}
	
	static testMethod void testSendEmail() {
		EmailSender testSender = new EmailSender();
		testSender.body('test body');
		testSender.subject('test subject');
		testSender.addRecipient('test recipient');
		testSender.includeCurrentUser();
		Messaging.SingleEmailMessage mail = testSender.build();
		System.assertEquals('test body', mail.getPlainTextBody());
		System.assertEquals('test subject', mail.getSubject());
		List<String> testRecipients = mail.getToAddresses();
		System.assertEquals('test recipient', testRecipients.get(0));
		System.assertEquals(2, testRecipients.size());
		System.assertEquals('test body', mail.getPlainTextBody());
	}
}