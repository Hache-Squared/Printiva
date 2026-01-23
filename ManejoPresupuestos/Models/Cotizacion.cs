namespace ManejoPresupuestos.Models
{
    public class CotizacionIndexRow
    {
        public int CotizacionId { get; set; }
        public int PedidoId { get; set; }
        public int CotizacionEstatusId { get; set; }
        public string CotizacionEstatus { get; set; }
        public DateTime FechaCreacion { get; set; }
        public DateTime? FechaVigencia { get; set; }
        public string Notas { get; set; }
        public decimal TotalModelado { get; set; }
        public decimal TotalProduccion { get; set; }
        public decimal TotalCotizado { get; set; }
        public decimal TotalPagado { get; set; }
        public decimal Saldo { get; set; }
    }

    public class CotizacionEstatus
    {
        public int CotizacionEstatusId { get; set; }
        public string Nombre { get; set; }
    }

    public class CotizacionItem
    {
        public int CotizacionItemId { get; set; }
        public int CotizacionId { get; set; }
        public int ConceptoTipoId { get; set; }
        public string ConceptoTipo { get; set; }
        public int? ProductoId { get; set; }
        public string ProductoNombre { get; set; }
        public string Concepto { get; set; }
        public decimal Cantidad { get; set; }
        public decimal PrecioUnitario { get; set; }
        public string Notas { get; set; }
    }
}
