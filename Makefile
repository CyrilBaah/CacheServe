.PHONY: install run build scan test clean help oci-export oci-scan sbom vuln-scan security-full

help:
	@echo "Available commands:"
	@echo "  install      - Install dependencies"
	@echo "  run          - Run the application locally"
	@echo "  build        - Build Docker image"
	@echo "  scan         - Run basic security scan"
	@echo "  vuln-scan    - Run vulnerability scan with Trivy"
	@echo "  oci-export   - Export image to OCI layout"
	@echo "  oci-scan     - Scan OCI image layout"
	@echo "  sbom         - Generate Software Bill of Materials"
	@echo "  security-full - Run complete security analysis"
	@echo "  test         - Test API endpoints"
	@echo "  clean        - Clean up containers and images"

install:
	pip install -r requirements_fixed.txt

run:
	uvicorn app:app --host 0.0.0.0 --port 8000 --reload

build:
	docker build -t cacheserve:latest .

scan:
	@echo "Running basic filesystem scan..."
	docker run --rm -v $(PWD):/workspace aquasec/trivy fs /workspace

vuln-scan:
	@echo "Running vulnerability scan on Docker image..."
	docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image cacheserve:latest

oci-export:
	@echo "Exporting Docker image to OCI layout..."
	@mkdir -p oci-layout
	docker save cacheserve:latest -o cacheserve-image.tar
	@if command -v skopeo >/dev/null 2>&1; then \
		skopeo copy docker-archive:cacheserve-image.tar oci:oci-layout:cacheserve:latest; \
	else \
		echo "Skopeo not found. Installing via Docker..."; \
		docker run --rm -v $(PWD):/workspace -w /workspace quay.io/skopeo/stable copy docker-archive:cacheserve-image.tar oci:oci-layout:cacheserve:latest; \
	fi
	@rm -f cacheserve-image.tar

oci-scan:
	@echo "Scanning OCI image layout..."
	docker run --rm -v $(PWD)/oci-layout:/oci-layout aquasec/trivy image --input /oci-layout

sbom:
	@echo "Generating Software Bill of Materials..."
	docker run --rm -v $(PWD):/workspace -v /var/run/docker.sock:/var/run/docker.sock anchore/syft cacheserve:latest -o spdx-json=/workspace/sbom.spdx.json

security-full: build vuln-scan oci-export oci-scan sbom
	@echo "Complete security analysis completed!"
	@echo "Results:"
	@echo "- Vulnerability scan: completed"
	@echo "- OCI layout scan: completed" 
	@echo "- SBOM generated: sbom.spdx.json"

test:
	@echo "Testing API endpoints..."
	@curl -X POST http://localhost:8000/cache/test -H "Content-Type: application/json" -d '{"value": "hello world"}'
	@echo ""
	@curl -X GET http://localhost:8000/cache/test
	@echo ""
	@curl -X GET http://localhost:8000/cache
	@echo ""

clean:
	docker rmi cacheserve:latest || true
	docker system prune -f
