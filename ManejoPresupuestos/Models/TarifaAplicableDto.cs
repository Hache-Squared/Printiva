namespace ManejoPresupuestos.Models
{
    // Lo mínimo necesario para costear (lo devuelve procTarifasObtenerAplicables)
    public class TarifaAplicableDto
    {
        public int TarifaId { get; set; }

        public string TarifaNombre { get; set; } = "";
        public int TarifaOrden { get; set; }

        public int? ImpresoraId { get; set; }
        public int? InventarioId { get; set; }

        public decimal Monto { get; set; }
        public string Moneda { get; set; } = "MXN";
    }
}