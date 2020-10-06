output "elb_dns_name" {
  description = "DNS Name of the ELB"
  value       = module.elb.this_elb_dns_name
}

output "web_domain" {
  value = module.records.this_route53_record_name
}
