from app.workflows.pipeline_manager import run_compliance_pipeline

class ComplianceService:
    async def run_compliance(self, document_text: str, rules: dict):
        return await run_compliance_pipeline(document_text, rules, from_file=False)

    async def run_compliance_file(self, file_path: str, rules: dict):
        return await run_compliance_pipeline(file_path, rules, from_file=True)
