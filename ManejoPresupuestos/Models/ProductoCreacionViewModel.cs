using Microsoft.AspNetCore.Mvc.Rendering;
using System.ComponentModel.DataAnnotations;

namespace ManejoPresupuestos.Models
{
    public class ProductoCreacionViewModel
    {
        public int ProductoId { get; set; }

        [Required]
        [StringLength(200)]
        public string Nombre { get; set; }

        [Required]
        public int ProductoCategoriaId { get; set; }

        public string SKU { get; set; }

        [Range(0, 999999999)]
        public decimal? PrecioSugerido { get; set; }

        public IEnumerable<SelectListItem> Categorias { get; set; } = Enumerable.Empty<SelectListItem>();
    }
}
