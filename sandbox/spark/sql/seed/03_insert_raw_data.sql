DELETE FROM local.raw.billing_subscriptions;

INSERT INTO local.raw.billing_subscriptions VALUES
('SUB-10001','USR-00001','PLAN-STARTER','active',   'monthly',NULL,   29.0, DATE'2024-01-15',NULL,            'JP','billing.subscriptions',TIMESTAMP'2024-01-15 00:00:00'),
('SUB-10002','USR-00042','PLAN-PRO',    'active',   'annual', 1188.0, 99.0, DATE'2024-02-01',NULL,            'US','billing.subscriptions',TIMESTAMP'2024-02-01 00:00:00'),
('SUB-10003','USR-00099','PLAN-STARTER','cancelled','monthly',NULL,    0.0, DATE'2024-01-20',DATE'2024-03-01','JP','billing.subscriptions',TIMESTAMP'2024-03-01 00:00:00'),
('SUB-10004','USR-00001','PLAN-PRO',    'active',   'annual', 1188.0, 99.0, DATE'2024-03-15',NULL,            'JP','billing.subscriptions',TIMESTAMP'2024-03-15 00:00:00'),
('SUB-10005','USR-00042','PLAN-STARTER','trialing', 'monthly',NULL,    0.0, DATE'2024-04-01',NULL,            'US','billing.subscriptions',TIMESTAMP'2024-04-01 00:00:00');
