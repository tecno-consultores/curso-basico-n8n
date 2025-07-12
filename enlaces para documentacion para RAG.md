# router OS
https://box.mikrotik.com/d/abfde6dccbff4e89aa5c/

# zabbix
https://www.zabbix.com/documentation/current/downloads/Zabbix_Documentation_7.4.en.pdf

# documentacion de N8N
git clone https://github.com/n8n-io/n8n-docs.git

cd n8n-docs

find . -name "*.md" -exec cat {} \; > ../n8n_docs_combined.md

convertir n8n_docs_combined.md a PDF
