data "google_iam_policy" "wiu_mysql_policy" {
  binding {
    role    = "roles/iam.workloadIdentityUser"
    members = [
      format("serviceAccount:%s.svc.id.goog[%s/%s]", var.project_id, "default", "mysql")
    ]
  }
}

resource "google_service_account" "mysql_sa" {
  account_id   = format("%s-mysql-sa", var.cluster_name)
  display_name = "MySQL Database Service Account"

  depends_on = [
    google_project_service.service
  ]
}

resource "google_service_account_iam_policy" "mysql_sa_policy" {
  service_account_id = google_service_account.mysql_sa.id
  policy_data        = data.google_iam_policy.wiu_mysql_policy.policy_data

  depends_on = [
    google_container_cluster.cluster
  ]
}

resource "google_project_iam_binding" "mysql_sa_binding" {
  role    = "roles/cloudsql.client"
  members = [
    format("serviceAccount:%s", google_service_account.mysql_sa.email)
  ]
}

resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "google_sql_database_instance" "mysql_instance" {
  name             = format("%s-mysql-%s", var.cluster_name, random_id.db_name_suffix.hex)
  database_version = "MYSQL_8_0"
  region           = var.region

  settings {
    tier              = "db-f1-micro"
    activation_policy = "ALWAYS"
    availability_type = "ZONAL"
    disk_autoresize   = false
    disk_size         = "10"
    disk_type         = "PD_SSD"
    pricing_plan      = "PER_USE"

    ip_configuration {
      ipv4_enabled    = "false"
      private_network = google_compute_network.vpc_network.self_link
    }

    location_preference {
      zone = var.zone
    }
  }

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }

  depends_on = [
    google_service_networking_connection.private_vpc_connection
  ]
}

resource "google_sql_database" "mysql_database" {
  name      = "study-mysql-database"
  instance  = google_sql_database_instance.mysql_instance.name
  collation = "utf8_general_ci"

  depends_on = [
    google_sql_database_instance.mysql_instance
  ]
}

resource "random_id" "mysql_password" {
  byte_length = 8
  keepers     = {
    name = google_sql_database_instance.mysql_instance.name
  }

  depends_on = [
    google_sql_database_instance.mysql_instance
  ]
}

resource "google_sql_user" "mysql_user" {
  name       = "admin"
  instance   = google_sql_database_instance.mysql_instance.name
  password   = random_id.mysql_password.hex

  depends_on = [
    google_sql_database_instance.mysql_instance
  ]
}