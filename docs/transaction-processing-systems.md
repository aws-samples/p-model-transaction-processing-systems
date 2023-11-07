# Transaction Processing Systems

We have explored the power of formal methods and P framework by leveraging them to validate the architecture of distributed transaction processing systems. Most transaction processing systems contain 5 key components.

1. ***Inbound***: The inbound component interfaces with inbound transport and extracts the transaction payload or transaction records.
2. ***Preprocess***: The preprocess component applies validation and enrichment rules before the transaction can be processed.
3. ***Core***: The core component executes core business logic for transaction processing.
4. ***Postprocess***: The postprocess component applies validation and enrichment rules before sending out the transaction.
5. ***Outbound***: The outbound component interfaces with outbound transport and sends out the transaction payload or transaction records.