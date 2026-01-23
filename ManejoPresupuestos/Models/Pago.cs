namespace ManejoPresupuestos.Models
{
    public class Pago
    {
        public int PagoId { get; set; }
        public int CotizacionId { get; set; }
        public int PagoTipoId { get; set; }
        public string PagoTipo { get; set; }
        public decimal Monto { get; set; }
        public DateTime FechaPago { get; set; }
        public string Metodo { get; set; }
        public string Referencia { get; set; }
        public string Notas { get; set; }
    }

    public class PagoTipo
    {
        public int PagoTipoId { get; set; }
        public string Nombre { get; set; }
    }
}
