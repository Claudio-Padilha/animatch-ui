# Política de Privacidade do Animatch

**Última atualização:** [PREENCHER DATA DE PUBLICAÇÃO]

> ⚠️ **Rascunho técnico — revisar com um advogado antes de publicar.** Este texto foi elaborado a partir do que o aplicativo Animatch efetivamente coleta e processa hoje (auditado diretamente no código-fonte). Ele **não substitui** revisão jurídica: confirme a razão social, o CNPJ, o endereço, o encarregado de dados (DPO) e a adequação às obrigações da LGPD (Lei nº 13.709/2018) com um profissional antes de tornar este texto público ou vinculá-lo nas lojas de aplicativos. Campos entre colchetes `[ASSIM]` precisam ser preenchidos.
>
> **NÃO PUBLICAR até que:**
> 1. Um advogado (idealmente com experiência em LGPD) revise e aprove o texto.
> 2. Todos os campos `[PREENCHER]` — razão social, CNPJ, endereço, e-mail de contato, encarregado de dados — estejam preenchidos com dados reais.
> 3. A lista de terceiros na seção 5 seja reconfirmada como atual no momento da publicação (provedores podem mudar).
>
> Este documento está deliberadamente **fora do hosting público** (não publicado como Artifact, não linkado em nenhuma loja) até essas três condições serem atendidas — ver a nota correspondente no plano de publish-readiness do projeto.

## 1. Quem somos

O Animatch é uma plataforma de conexão entre criadores de bovinos (Nelore) e equinos (Mangalarga Marchador, Quarto de Milha, Crioulo) para fins de acasalamento, aquisição de sêmen/embriões e negócios de genética animal no Brasil.

- **Controlador dos dados:** [RAZÃO SOCIAL DA EMPRESA]
- **CNPJ:** [PREENCHER]
- **Endereço:** [PREENCHER]
- **Contato para assuntos de privacidade:** [E-MAIL DE CONTATO, ex.: privacidade@animatch.com.br]
- **Encarregado de Dados (DPO):** [NOME/CONTATO, se aplicável]

## 2. Quais dados coletamos

### 2.1. Dados de cadastro e autenticação
Nome, e-mail e telefone, coletados durante o cadastro. A autenticação (login/logout, criação de conta) é processada por um provedor terceirizado (Auth0) — ver seção 5.

### 2.2. Dados de verificação de perfil
Durante a ativação do perfil, solicitamos CPF e uma foto de perfil, para confirmar a identidade do criador antes de liberar o acesso à busca de pares (matching) e ao chat com outros criadores.

### 2.3. Dados de propriedade e endereço
Nome da propriedade/fazenda, cidade, estado e CEP. Esses dados são usados para o funcionamento principal do aplicativo: encontrar outros criadores geograficamente próximos. **Não coletamos a localização precisa (GPS) do seu dispositivo** — o Animatch usa apenas o endereço informado por você.

### 2.4. Dados de associações de criadores
Código e nome da associação (ex.: ABCZ, ABQM, ABCCrioulo, ABCAngus, ABCCMM), número de registro informado por você, e, opcionalmente, uma foto da carteirinha de associado ou do Certificado de Registro Genealógico (CRG) de um animal, enviada como comprovação do registro informado. Essas informações passam por análise manual de um revisor antes de serem consideradas verificadas.

### 2.5. Dados sobre os animais cadastrados
Nome, raça, sexo, fotos, descrição, número de registro, índices genéticos/DEP e disponibilidade para acasalamento dos animais que você cadastra no aplicativo.

### 2.6. Comunicações
Mensagens trocadas com outros criadores dentro do aplicativo (chat), processadas por um provedor terceirizado (Stream) — ver seção 5. Se você optar por continuar a conversa fora do aplicativo (ex.: WhatsApp), essa comunicação passa a ser regida pela política de privacidade do respectivo serviço, não pela nossa.

### 2.7. Dados técnicos
Token de notificação push do seu dispositivo, usado exclusivamente para enviar notificações sobre matches e mensagens (ex.: via Firebase Cloud Messaging).

### 2.8. O que não coletamos
Não coletamos localização em tempo real (GPS), não exibimos anúncios de terceiros e não realizamos rastreamento analítico do seu comportamento fora das finalidades descritas nesta política.

## 3. Para que usamos seus dados

- Criar e gerenciar sua conta e perfil de criador.
- Verificar sua identidade e vínculo com associações de criadores antes de liberar funcionalidades de matching.
- Conectar você a outros criadores com base em proximidade geográfica (o principal sinal de correspondência da plataforma).
- Exibir seu perfil, animais cadastrados e disponibilidade a outros criadores dentro do aplicativo.
- Permitir comunicação entre criadores interessados em uma negociação.
- Enviar notificações sobre novos matches e mensagens.
- Cumprir obrigações legais e regulatórias aplicáveis.

## 4. Base legal (LGPD, art. 7º)

Tratamos seus dados com base em:
- **Execução de contrato:** para fornecer as funcionalidades essenciais do aplicativo (cadastro, matching, comunicação).
- **Consentimento:** para o envio de documentos de verificação de associação e fotos, que você opta por enviar voluntariamente.
- **Legítimo interesse:** para prevenção a fraudes e verificação de identidade de criadores, dentro dos limites legais.

## 5. Com quem compartilhamos seus dados

Compartilhamos dados pessoais apenas na medida necessária para operar o aplicativo:

| Terceiro | Finalidade | Dados compartilhados |
|---|---|---|
| **Auth0** | Autenticação e login | Nome, e-mail |
| **Firebase (Google)** | Notificações push | Token do dispositivo |
| **Cloudinary** | Armazenamento de fotos e documentos | Fotos de perfil, de animais e documentos de associação |
| **Stream** | Chat entre criadores | Nome, identificador de usuário, conteúdo das mensagens |
| **Railway** | Hospedagem da infraestrutura e banco de dados | Todos os dados de perfil, animais e associações |
| **Outros criadores no app** | Funcionamento do matching | Nome, propriedade, cidade/estado, fotos, animais cadastrados, associações e disponibilidade — visíveis a criadores com quem você tenha match ou que visualizem seu perfil na busca |

Não vendemos seus dados pessoais a terceiros.

**Transferência internacional:** alguns dos provedores acima podem processar ou armazenar dados fora do Brasil, conforme suas respectivas políticas. Ao usar o Animatch, você concorda com essas transferências, feitas com as salvaguardas exigidas pela LGPD.

## 6. Por quanto tempo guardamos seus dados

Mantemos seus dados enquanto sua conta estiver ativa. Após a exclusão da conta, os dados são removidos ou anonimizados dentro de um prazo razoável, exceto quando a retenção for exigida por lei (ex.: obrigações fiscais ou regulatórias) ou para exercício regular de direitos em processos judiciais/administrativos.

## 7. Seus direitos como titular de dados (LGPD, art. 18)

Você pode, a qualquer momento, solicitar:
- Confirmação da existência de tratamento de dados.
- Acesso aos seus dados.
- Correção de dados incompletos, inexatos ou desatualizados.
- Anonimização, bloqueio ou eliminação de dados desnecessários ou tratados em desconformidade com a lei.
- Portabilidade dos dados a outro fornecedor de serviço.
- Eliminação dos dados tratados com base no seu consentimento.
- Informação sobre com quais entidades públicas ou privadas compartilhamos seus dados.
- Revogação do consentimento, quando aplicável.

Para exercer esses direitos, entre em contato pelo e-mail informado na seção 1.

## 8. Segurança

Adotamos medidas técnicas e administrativas razoáveis para proteger seus dados contra acessos não autorizados e situações acidentais ou ilícitas de destruição, perda, alteração, comunicação ou difusão. Nenhum sistema é 100% seguro, e nos comprometemos a notificar você e as autoridades competentes em caso de incidente de segurança relevante, conforme exigido pela LGPD.

## 9. Uso por menores de idade

O Animatch não é direcionado a menores de 18 anos e não coletamos intencionalmente dados de menores.

## 10. Alterações nesta política

Podemos atualizar esta política periodicamente. Notificaremos mudanças relevantes por meio do aplicativo ou por e-mail. A data no topo deste documento indica a versão mais recente.

## 11. Contato

Dúvidas sobre esta política ou sobre o tratamento dos seus dados podem ser enviadas para: [E-MAIL DE CONTATO]
