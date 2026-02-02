namespace ManejoPresupuestos.Models
{
    public class TarifaConceptoDto
    {
        public int TarifaConceptoId { get; set; }
        public string Codigo { get; set; } = "";
        public string Nombre { get; set; } = "";
        public string Unidad { get; set; } = "";
        public int Orden { get; set; }
    }
}