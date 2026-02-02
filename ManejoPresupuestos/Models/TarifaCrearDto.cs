namespace ManejoPresupuestos.Models
{
    public class TarifaCrearDto
    {
        public string TarifaConceptoCodigo { get; set; } = "";
        public decimal Monto { get; set; }
        public string Moneda { get; set; } = "MXN";

        public string Nombre { get; set; } = "";
        public int Orden { get; set; } = 100;

        public int? InventarioId { get; set; }
        public int? ImpresoraId { get; set; }
    }
}