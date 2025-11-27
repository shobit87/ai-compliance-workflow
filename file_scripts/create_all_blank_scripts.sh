#!/bin/bash

echo "📁 Creating file_scripts folder..."
mkdir -p file_scripts

echo "📝 Creating blank script files..."

scripts=(
    # Core
    "create_main.sh"
    "create_config.sh"
    "create_cache_config.sh"

    # Routers
    "create_compliance_router.sh"
    "create_document_router.sh"
    "create_audit_router.sh"
    "create_health_router.sh"

    # Workflows
    "create_pipeline_manager.sh"
    "create_chunker.sh"
    "create_validator.sh"
    "create_summarizer.sh"
    "create_hallucination_detector.sh"

    # Critic / refine
    "create_critic.sh"
    "create_refine.sh"

    # Detectors
    "create_pii_detector.sh"
    "create_keyword_matcher.sh"
    "create_rule_engine.sh"

    # Scorers
    "create_compliance_score.sh"
    "create_risk_score.sh"

    # Utils
    "create_llm_client.sh"
    "create_tokenizer.sh"
    "create_hash_generator.sh"
    "create_file_loader.sh"
    "create_text_cleaner.sh"
    "create_vector_store.sh"
    "create_common.sh"

    # Services
    "create_compliance_service.sh"
    "create_document_service.sh"
    "create_audit_service.sh"

    # Schemas
    "create_compliance_schema.sh"
    "create_document_schema.sh"
    "create_audit_schema.sh"

    # DB + Repos
    "create_db_session.sh"
    "create_base_repo.sh"
    "create_document_repo.sh"
    "create_compliance_repo.sh"
    "create_audit_repo.sh"

    # Tests
    "create_test_api.sh"
    "create_test_workflow_cache.sh"
    "create_test_token_optimization.sh"
    "create_test_detectors.sh"
    "create_test_critic.sh"
    "create_conftest.sh"

    # Setup files
    "create_dockerfile.sh"
    "create_requirements.sh"
    "create_readme.sh"
)

# Create blank files
for script in "${scripts[@]}"; do
    touch file_scripts/$script
    echo "#!/bin/bash" > file_scripts/$script
done

echo "🔐 Making scripts executable..."
chmod +x file_scripts/*.sh

echo "✅ All blank script files created successfully inside file_scripts/"
