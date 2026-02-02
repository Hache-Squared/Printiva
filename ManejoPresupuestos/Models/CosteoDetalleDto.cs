namespace ManejoPresupuestos.Models
{
    public class CosteoDetalleDto
    {
        public string ConceptoCodigo { get; set; } = "";

        public int? InventarioId { get; set; }
        public int? ImpresoraId { get; set; }

        public int TarifaId { get; set; }
        public string TarifaNombre { get; set; } = "";
        public int TarifaOrden { get; set; }

        public decimal MontoTarifa { get; set; }   // monto unitario
        public decimal Cantidad { get; set; }      // cantidad consumida
        public decimal Subtotal { get; set; }      // MontoTarifa * Cantidad

        public string Moneda { get; set; } = "MXN";
    }
}