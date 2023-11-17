# Variables
DB_INSTANCE_IDENTIFIER="mi-db-instance"
DB_NAME="mi-base-de-datos"
DB_MASTER_USERNAME="root"
DB_MASTER_PASSWORD="root1234"
DB_SECURITY_GROUP_NAME="mi-grupo-seguridad"

# Crear la instancia de base de datos MySQL
aws rds create-db-instance \
    --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
    --db-instance-class db.t2.micro \
    --engine mysql \
    --allocated-storage 20 \
    --master-username $DB_MASTER_USERNAME \
    --master-user-password $DB_MASTER_PASSWORD \
    --enable-publicly-accessible \
    --no-auto-minor-version-upgrade \
    --enable-cloudwatch-logs-exports '["error","general","slowquery","audit"]'

# Esperar a que la instancia esté disponible
echo "Esperando a que la instancia de base de datos esté disponible..."
aws rds wait db-instance-available --db-instance-identifier $DB_INSTANCE_IDENTIFIER
echo "Instancia de base de datos creada correctamente."

# Crear un grupo de seguridad
aws ec2 create-security-group \
    --group-name $DB_SECURITY_GROUP_NAME \
    --description "Grupo de seguridad para la base de datos MySQL"

# Obtener el ID del grupo de seguridad recién creado
DB_SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
    --group-names $DB_SECURITY_GROUP_NAME \
    --query 'SecurityGroups[0].GroupId' \
    --output text)

# Agregar reglas al grupo de seguridad
aws ec2 authorize-security-group-ingress \
    --group-id $DB_SECURITY_GROUP_ID \
    --protocol tcp \
    --port 3306 \
    --cidr 0.0.0.0/0

# Asociar el grupo de seguridad a la instancia de base de datos
aws rds modify-db-instance \
    --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
    --vpc-security-group-ids $DB_SECURITY_GROUP_ID

# Habilitar autenticación de contraseña para la instancia de base de datos
aws rds modify-db-instance \
    --db-instance-identifier $DB_INSTANCE_IDENTIFIER \
    --apply-immediately \
    --no-enable-iam-database-authentication

echo "Configuración completada."

