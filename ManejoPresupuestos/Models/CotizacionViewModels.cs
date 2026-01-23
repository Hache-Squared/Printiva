using Microsoft.AspNetCore.Mvc.Rendering;
using System.ComponentModel.DataAnnotations;

namespace ManejoPresupuestos.Models
{
    public class CotizacionItemEdicionViewModel
    {
        public int CotizacionItemId { get; set; }

        [Required]
        public int ConceptoTipoId { get; set; }

        public int? ProductoId { get; set; }

        [Required]
        [StringLength(200)]
        public string Concepto { get; set; }

        [Range(0.01, 999999999)]
        public decimal Cantidad { get; set; }

        [Range(0, 999999999)]
        public decimal PrecioUnitario { get; set; }

        [StringLength(500)]
        public string Notas { get; set; }
    }

    public class CotizacionEdicionViewModel
    {
        public int CotizacionId { get; set; }

        [Required]
        public int PedidoId { get; set; }

        [Required]
        public int CotizacionEstatusId { get; set; }

        public DateTime? FechaVigencia { get; set; }

        public string Notas { get; set; }

        public List<CotizacionItemEdicionViewModel> Items { get; set; } = new();

        public IEnumerable<SelectListItem> Estatus { get; set; } = Enumerable.Empty<SelectListItem>();
    }

    public class CotizacionDetalleViewModel
    {
        public CotizacionIndexRow Cotizacion { get; set; }
        public IEnumerable<CotizacionItem> Items { get; set; } = Enumerable.Empty<CotizacionItem>();
        public IEnumerable<Pago> Pagos { get; set; } = Enumerable.Empty<Pago>();
    }

    public class PagoEdicionViewModel
    {
        public int PagoId { get; set; }

        [Required]
        public int CotizacionId { get; set; }

        [Required]
        public int PagoTipoId { get; set; }

        [Range(0.01, 999999999)]
        public decimal Monto { get; set; }

        [Required]
        public DateTime FechaPago { get; set; } = DateTime.Today;

        public string Metodo { get; set; }
        public string Referencia { get; set; }
        public string Notas { get; set; }

        public IEnumerable<SelectListItem> Tipos { get; set; } = Enumerable.Empty<SelectListItem>();
    }
}
