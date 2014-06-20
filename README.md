SI2-LI51N-GRP5
==============

Sistemas de Informação II - Trabalho Prático 3 - Grupo 5

#####Restrições de integridade adicionadas ao modelo inícial
```sql
ALTER TABLE [dbo].[Ocorrencia] ADD  DEFAULT ('inicial') FOR [estado]
ALTER TABLE [dbo].[Ocorrencia]  WITH CHECK ADD CHECK  (([estado]='concluído' OR [estado]='cancelado' OR [estado]='recusado' OR [estado]='em resolução' OR [estado]='em processamento' OR [estado]='inicial'))
ALTER TABLE [dbo].[Ocorrencia]  WITH CHECK ADD CHECK  (([tipo]='trivial' OR [tipo]='crítico' OR [tipo]='urgente'))
```
